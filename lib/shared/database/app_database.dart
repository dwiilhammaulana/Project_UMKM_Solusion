import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_seed.dart';

class AppDatabase {
  AppDatabase({
    this.inMemory = false,
    this.databaseName = _defaultDatabaseName,
    DatabaseFactory? databaseFactoryOverride,
  }) : _databaseFactoryOverride = databaseFactoryOverride;

  static const String _defaultDatabaseName = 'warung_kopi_pos.db';
  static const int schemaVersion = 3;

  final bool inMemory;
  final String databaseName;
  final DatabaseFactory? _databaseFactoryOverride;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (_openingDatabase != null) {
      return _openingDatabase!;
    }

    _openingDatabase = _openDatabase();
    final database = await _openingDatabase!;
    _database = database;
    _openingDatabase = null;
    return database;
  }

  Future<Database> _openDatabase() async {
    final factory = _databaseFactory;
    final path = inMemory
        ? inMemoryDatabasePath
        : p.join(await factory.getDatabasesPath(), databaseName);

    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion == newVersion) {
            return;
          }
          await _migrateSchema(db, oldVersion, newVersion);
        },
      ),
    );

    await seedDatabaseIfNeeded(database);
    return database;
  }

  DatabaseFactory get _databaseFactory {
    if (_databaseFactoryOverride != null) {
      return _databaseFactoryOverride;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return databaseFactory;
    }

    sqfliteFfiInit();
    if (inMemory) {
      return databaseFactoryFfiNoIsolate;
    }
    return databaseFactoryFfi;
  }

  Future<void> close() async {
    if (_database == null) {
      return;
    }
    await _database!.close();
    _database = null;
    _openingDatabase = null;
  }

  Future<void> _createSchema(Database db) async {
    const statements = <String>[
      '''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT
      )
      ''',
      '''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sell_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        stock_qty INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL,
        rack_location TEXT,
        image_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
      ''',
      '''
      CREATE TABLE app_profile (
        id TEXT PRIMARY KEY,
        store_name TEXT NOT NULL,
        store_subtitle TEXT NOT NULL,
        owner_name TEXT,
        photo_path TEXT
      )
      ''',
      '''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        transaction_code TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
      ''',
      '''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        sell_price REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
      ''',
      '''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL UNIQUE,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        original_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        due_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      )
      ''',
      '''
      CREATE TABLE debt_payments (
        id TEXT PRIMARY KEY,
        debt_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        paid_at TEXT NOT NULL,
        FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      )
      ''',
      '''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        reference_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      )
      ''',
      '''
      CREATE TABLE operational_costs (
        id TEXT PRIMARY KEY,
        month_year TEXT NOT NULL,
        cost_name TEXT NOT NULL,
        amount REAL NOT NULL
      )
      ''',
      'CREATE INDEX idx_transactions_created_at ON transactions(created_at)',
      'CREATE INDEX idx_transactions_customer_id ON transactions(customer_id)',
      'CREATE INDEX idx_transaction_items_transaction_id ON transaction_items(transaction_id)',
      'CREATE INDEX idx_debts_customer_id ON debts(customer_id)',
      'CREATE INDEX idx_debts_updated_at ON debts(updated_at)',
      'CREATE INDEX idx_debt_payments_debt_id ON debt_payments(debt_id)',
      'CREATE INDEX idx_stock_movements_product_created_at ON stock_movements(product_id, created_at)',
    ];

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _addColumnIfNeeded(
        db,
        table: 'products',
        column: 'image_path',
        definition: 'TEXT',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_profile (
          id TEXT PRIMARY KEY,
          store_name TEXT NOT NULL,
          store_subtitle TEXT NOT NULL,
          owner_name TEXT,
          photo_path TEXT
        )
      ''');
      final existingCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM app_profile'),
          ) ??
          0;
      if (existingCount == 0) {
        await db.insert('app_profile', {
          'id': 'store-main',
          'store_name': 'Warung Kopi Pertigaan Jati',
          'store_subtitle':
              'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
          'owner_name': 'Pemilik Toko',
          'photo_path': null,
        });
      }
    }

    if (oldVersion < 3 && newVersion >= 3) {
      const dummyTransactionIds = [
        'trx-001',
        'trx-002',
        'trx-003',
        'trx-004',
        'trx-005',
        'trx-006',
      ];
      const dummyDebtIds = ['debt-001', 'debt-002', 'debt-003'];
      const dummyPaymentIds = ['pay-001', 'pay-002'];
      const dummyStockMovementIds = [
        'stm-001',
        'stm-002',
        'stm-003',
        'stm-004'
      ];

      final transactionPlaceholders = List.filled(
        dummyTransactionIds.length,
        '?',
      ).join(', ');
      final debtPlaceholders = List.filled(dummyDebtIds.length, '?').join(', ');
      final paymentPlaceholders = List.filled(
        dummyPaymentIds.length,
        '?',
      ).join(', ');
      final stockPlaceholders = List.filled(
        dummyStockMovementIds.length,
        '?',
      ).join(', ');

      if (await _tableExists(db, 'debt_payments')) {
        await db.delete(
          'debt_payments',
          where: 'id IN ($paymentPlaceholders)',
          whereArgs: dummyPaymentIds,
        );
      }
      if (await _tableExists(db, 'debts')) {
        await db.delete(
          'debts',
          where: 'id IN ($debtPlaceholders)',
          whereArgs: dummyDebtIds,
        );
      }
      if (await _tableExists(db, 'stock_movements')) {
        await db.delete(
          'stock_movements',
          where: 'id IN ($stockPlaceholders)',
          whereArgs: dummyStockMovementIds,
        );
      }
      if (await _tableExists(db, 'transactions')) {
        await db.delete(
          'transactions',
          where: 'id IN ($transactionPlaceholders)',
          whereArgs: dummyTransactionIds,
        );
      }
    }
  }

  Future<void> _addColumnIfNeeded(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    final hasColumn = rows.any((row) => row['name'] == column);
    if (!hasColumn) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      ''',
      [table],
    );
    return result.isNotEmpty;
  }
}
