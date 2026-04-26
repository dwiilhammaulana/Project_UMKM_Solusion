import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:warung_kopi_pos/app/app.dart';
import 'package:warung_kopi_pos/shared/database/app_database.dart';
import 'package:warung_kopi_pos/shared/models/app_models.dart';
import 'package:warung_kopi_pos/shared/state/app_state.dart';
import 'package:warung_kopi_pos/shared/utils/media_picker.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    List<String?> pickerResponses = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase(inMemory: true)),
          mediaPickerProvider.overrideWithValue(
            FakeMediaPickerService(List<String?>.from(pickerResponses)),
          ),
        ],
        child: const WarungKopiApp(),
      ),
    );

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final errorFinder = find.text('Database lokal gagal dimuat');
      if (errorFinder.evaluate().isNotEmpty) {
        final visibleTexts = find.byType(Text).evaluate().map((element) {
          final widget = element.widget as Text;
          return widget.data ?? widget.textSpan?.toPlainText() ?? '<rich-text>';
        }).join(' | ');
        fail('App bootstrap fell into error state: $visibleTexts');
      }
      if (find.text('Warung Kopi Pertigaan Jati').evaluate().isNotEmpty) {
        break;
      }
    }

    return ProviderScope.containerOf(
        tester.element(find.byType(WarungKopiApp)));
  }

  Future<void> openMoreAndTap(WidgetTester tester, String keyValue) async {
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(keyValue)));
    await tester.pumpAndSettle();
  }

  Future<void> openCashierHistoryTab(WidgetTester tester) async {
    await tester.tap(find.text('Kasir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cashier-tab-history')));
    await tester.pumpAndSettle();
  }

  Future<TransactionRecord> createTransaction(
    ProviderContainer container, {
    String? customerId,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final state = container.read(posStateProvider);
    state.addToCart(state.products.first);
    if (customerId != null) {
      state.setSelectedCustomer(customerId);
    }
    state.setPaymentMethod(paymentMethod);
    return state.checkout();
  }

  testWidgets('app opens dashboard and can navigate from bottom nav', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Warung Kopi Pertigaan Jati'), findsOneWidget);

    await tester.tap(find.text('Produk'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Produk'), findsOneWidget);
  });

  testWidgets('reports screen opens without blank state', (tester) async {
    await pumpApp(tester);

    await openMoreAndTap(tester, 'more-reports-link');

    expect(
        find.text('Ringkasan bisnis yang lebih enak dibaca.'), findsOneWidget);
    expect(find.text('Modal Produk'), findsOneWidget);
    expect(find.text('Komponen Net Profit'), findsOneWidget);
    expect(find.text('Biaya Operasional Bulanan'), findsOneWidget);
  });

  testWidgets(
    'cashier flow enforces registered customer for BON and can checkout',
    (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.text('Kasir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah').first);
      await tester.pumpAndSettle();

      container.read(posStateProvider).setPaymentMethod(PaymentMethod.bon);
      await tester.pumpAndSettle();
      await expectLater(
        container.read(posStateProvider).checkout(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Transaksi BON wajib memilih pelanggan'),
          ),
        ),
      );

      container.read(posStateProvider).setSelectedCustomer('cus-001');
      await tester.pumpAndSettle();

      final transaction = await container.read(posStateProvider).checkout();
      await tester.pumpAndSettle();

      expect(transaction.paymentMethod, PaymentMethod.bon);
    },
  );

  testWidgets('cart quantity cannot exceed available stock', (tester) async {
    final container = await pumpApp(tester);
    final product = container
        .read(posStateProvider)
        .products
        .firstWhere((item) => item.stockQty > 0);

    for (var i = 0; i < product.stockQty; i++) {
      container.read(posStateProvider).addToCart(product);
    }

    expect(
      () => container.read(posStateProvider).addToCart(product),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Stok ${product.name} tidak cukup'),
        ),
      ),
    );
  });

  testWidgets('cashier history tab shows seeded transactions and metrics', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final transaction = await createTransaction(container);
    await tester.pumpAndSettle();

    await openCashierHistoryTab(tester);

    expect(
      find.byKey(Key('transaction-history-tile-${transaction.id}')),
      findsOneWidget,
    );
    expect(find.text('${transaction.totalQuantity} qty'), findsWidgets);
    expect(find.text('${transaction.lineItemCount} jenis item'), findsWidgets);
  });

  testWidgets('transaction history tile opens detail transaction screen', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final transaction = await createTransaction(container);
    await tester.pumpAndSettle();

    await openCashierHistoryTab(tester);
    await tester
        .tap(find.byKey(Key('transaction-history-tile-${transaction.id}')));
    await tester.pumpAndSettle();

    expect(find.text(transaction.transactionCode), findsWidgets);
    expect(find.text('Ringkasan Transaksi'), findsOneWidget);
    expect(find.text('${transaction.totalQuantity}'), findsWidgets);
    expect(find.text('${transaction.lineItemCount}'), findsWidgets);
  });

  testWidgets('receipt sheet can open detail transaction after checkout', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Kasir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cashier-checkout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Transaksi Berhasil'), findsOneWidget);

    final latestTransaction =
        container.read(posStateProvider).transactions.first;

    await tester.tap(find.byKey(const Key('receipt-view-detail-button')));
    await tester.pumpAndSettle();

    expect(find.text(latestTransaction.transactionCode), findsWidgets);
    expect(find.text('Detail Item'), findsOneWidget);
  });

  testWidgets('customers search works and customer form opens', (tester) async {
    await pumpApp(tester);

    await openMoreAndTap(tester, 'more-customers-link');

    await tester.enterText(
      find.byKey(const Key('customers-search-field')),
      'Rina',
    );
    await tester.pumpAndSettle();

    expect(find.text('Bu Rina'), findsOneWidget);

    await tester.tap(find.byKey(const Key('customers-add-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pelanggan Baru'), findsOneWidget);
  });

  testWidgets('customer transaction history opens shared transaction detail', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final transaction = await createTransaction(
      container,
      customerId: 'cus-001',
    );
    await tester.pumpAndSettle();

    await openMoreAndTap(tester, 'more-customers-link');

    await tester.enterText(
      find.byKey(const Key('customers-search-field')),
      'Slamet',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buka Profil').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(transaction.transactionCode));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Transaksi'), findsOneWidget);
    expect(find.text('Detail Item'), findsOneWidget);
  });

  testWidgets('debt payment updates ui flow', (tester) async {
    final container = await pumpApp(tester);
    await createTransaction(
      container,
      customerId: 'cus-001',
      paymentMethod: PaymentMethod.bon,
    );
    await tester.pumpAndSettle();

    await openMoreAndTap(tester, 'more-debts-link');
    expect(find.text('Daftar Bon Aktif'), findsOneWidget);

    final firstDebt = container.read(posStateProvider).activeDebtsSorted.first;
    final before = firstDebt.remainingAmount;
    final paymentAmount = before > 1000 ? 1000.0 : before;
    await container.read(posStateProvider).recordDebtPayment(
          debtId: firstDebt.id,
          amount: paymentAmount,
          paymentMethod: PaymentMethod.cash,
        );
    await tester.pumpAndSettle();

    final updated = container
        .read(posStateProvider)
        .debts
        .firstWhere((item) => item.id == firstDebt.id);

    expect(updated.remainingAmount, lessThan(before));
  });

  testWidgets('debt payment cannot exceed remaining debt', (tester) async {
    final container = await pumpApp(tester);
    final transaction = await createTransaction(
      container,
      customerId: 'cus-001',
      paymentMethod: PaymentMethod.bon,
    );
    await tester.pumpAndSettle();

    final debt = container
        .read(posStateProvider)
        .debts
        .firstWhere((item) => item.transactionId == transaction.id);

    await expectLater(
      container.read(posStateProvider).recordDebtPayment(
            debtId: debt.id,
            amount: debt.remainingAmount + 1000,
            paymentMethod: PaymentMethod.cash,
          ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Nominal pembayaran melebihi sisa utang'),
        ),
      ),
    );
  });

  testWidgets('operational cost input updates monthly cost and net profit', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final state = container.read(posStateProvider);
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    final beforeOperationalCost = state.operationalCostTotalByMonth(month);
    final beforeNetProfit = state.reportSummaries.last.netProfit;

    await state.saveOperationalCost(
      monthYear: month,
      costName: 'Sewa Tambahan',
      amount: 250000,
    );
    await tester.pumpAndSettle();

    final updatedState = container.read(posStateProvider);
    expect(
      updatedState.operationalCostTotalByMonth(month),
      beforeOperationalCost + 250000,
    );
    expect(
      updatedState.reportSummaries.last.netProfit,
      beforeNetProfit - 250000,
    );
  });

  testWidgets('product image can be uploaded and placeholder starts empty', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      pickerResponses: ['C:/mock/product-kopi.png'],
    );

    await tester.tap(find.text('Produk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('products-add-button')));
    await tester.pumpAndSettle();

    expect(find.text('Foto\nproduk'), findsOneWidget);

    await container.read(posStateProvider).saveProduct(
          name: 'Kopi Test',
          categoryId: container.read(posStateProvider).categories.first.id,
          sellPrice: 15000,
          costPrice: 7000,
          stockQty: 12,
          minStock: 3,
          unit: 'gelas',
          rackLocation: 'Bar X1',
          imagePath: 'C:/mock/product-kopi.png',
        );
    await tester.pumpAndSettle();

    final created = container
        .read(posStateProvider)
        .products
        .firstWhere((item) => item.name == 'Kopi Test');
    expect(created.imagePath, 'C:/mock/product-kopi.png');
  });

  testWidgets('product can be deleted from long press action', (tester) async {
    final container = await pumpApp(tester);

    await container.read(posStateProvider).saveProduct(
          name: 'Produk Hapus',
          categoryId: container.read(posStateProvider).categories.first.id,
          sellPrice: 13000,
          costPrice: 6000,
          stockQty: 5,
          minStock: 1,
          unit: 'gelas',
        );
    await tester.pumpAndSettle();

    final created = container
        .read(posStateProvider)
        .products
        .firstWhere((item) => item.name == 'Produk Hapus');

    await tester.tap(find.text('Produk'));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(Key('product-card-${created.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Hapus Produk'), findsOneWidget);

    await tester.tap(find.byKey(Key('product-delete-button-${created.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Hapus produk?'), findsOneWidget);

    await tester.tap(find.byKey(Key('product-confirm-delete-${created.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Produk Hapus'), findsNothing);
  });

  testWidgets('store profile image can be uploaded and cleared',
      (tester) async {
    final container = await pumpApp(
      tester,
      pickerResponses: ['C:/mock/store-profile.png'],
    );

    await tester.tap(find.byKey(const Key('dashboard-edit-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('Profil Toko'), findsOneWidget);

    await container.read(posStateProvider).saveAppProfile(
          storeName: 'Warung Kopi Pertigaan Jati',
          storeSubtitle: 'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
          ownerName: 'Pemilik Toko',
          photoPath: 'C:/mock/store-profile.png',
        );
    await tester.pumpAndSettle();

    expect(
      container.read(posStateProvider).appProfile.photoPath,
      'C:/mock/store-profile.png',
    );

    await container.read(posStateProvider).saveAppProfile(
          storeName: 'Warung Kopi Pertigaan Jati',
          storeSubtitle: 'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
          ownerName: 'Pemilik Toko',
          photoPath: null,
        );
    await tester.pumpAndSettle();

    expect(container.read(posStateProvider).appProfile.photoPath, isNull);
  });

  test(
    'database migration preserves old data and adds new image/profile fields',
    () async {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;
      final name =
          'warung_kopi_migration_test_${DateTime.now().microsecondsSinceEpoch}.db';
      final dbPath = p.join(await factory.getDatabasesPath(), name);

      final oldDb = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE categories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT
            )
          ''');
            await db.execute('''
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
              is_active INTEGER NOT NULL DEFAULT 1
            )
          ''');
            await db.insert('categories', {
              'id': 'cat-1',
              'name': 'Kopi',
              'description': null,
            });
            await db.insert('products', {
              'id': 'prd-legacy',
              'category_id': 'cat-1',
              'name': 'Produk Lama',
              'sell_price': 10000,
              'cost_price': 5000,
              'stock_qty': 4,
              'min_stock': 1,
              'unit': 'gelas',
              'rack_location': 'Rak A',
              'is_active': 1,
            });
          },
        ),
      );
      await oldDb.close();

      final appDatabase = AppDatabase(
        databaseName: name,
        databaseFactoryOverride: factory,
      );
      final upgraded = await appDatabase.database;

      final productRows = await upgraded.query(
        'products',
        where: 'id = ?',
        whereArgs: ['prd-legacy'],
      );
      final profileRows = await upgraded.query('app_profile');

      expect(productRows.single['name'], 'Produk Lama');
      expect(productRows.single['image_path'], isNull);
      expect(profileRows, isNotEmpty);

      await appDatabase.close();
      await factory.deleteDatabase(dbPath);
      final file = File(dbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    },
  );
}

class FakeMediaPickerService implements MediaPickerService {
  FakeMediaPickerService(this.responses);

  final List<String?> responses;

  @override
  Future<String?> pickImagePath() async {
    if (responses.isEmpty) {
      return null;
    }
    return responses.removeAt(0);
  }
}
