import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warung_kopi_pos/app/app.dart';
import 'package:warung_kopi_pos/shared/auth/auth_controller.dart';
import 'package:warung_kopi_pos/shared/biometrics/biometric_service.dart';
import 'package:warung_kopi_pos/shared/models/app_models.dart';
import 'package:warung_kopi_pos/shared/state/app_state.dart';
import 'package:warung_kopi_pos/shared/utils/app_formatters.dart';
import 'package:warung_kopi_pos/shared/utils/media_picker.dart';

import 'support/fake_pos_repository.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    List<String?> pickerResponses = const [],
    AuthController? authController,
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
          posRepositoryProvider.overrideWithValue(
            FakePosRepository(),
          ),
          authControllerProvider.overrideWith((ref) {
            return authController ?? AuthController.test();
          }),
          biometricServiceProvider.overrideWithValue(
            FakeBiometricAuthenticator(),
          ),
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
    await tester.tap(find.byKey(const Key('bottom-nav-/more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(keyValue)));
    await tester.pumpAndSettle();
  }

  Future<void> openCashierHistoryTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cashier-tab-history')));
    await tester.pumpAndSettle();
  }

  Product firstNasiPaketProduct(ProviderContainer container) {
    final state = container.read(posStateProvider);
    return state.products.firstWhere(state.isNasiPaketProduct);
  }

  Product firstStockProduct(ProviderContainer container) {
    final state = container.read(posStateProvider);
    return state.products.firstWhere((product) {
      return !state.isNasiPaketProduct(product);
    });
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

    await tester.tap(find.byKey(const Key('bottom-nav-/products')));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Produk'), findsOneWidget);
  });

  testWidgets('cashier can open products without add product button', (
    tester,
  ) async {
    await pumpApp(
      tester,
      authController: AuthController.test(role: 'kasir'),
    );

    expect(find.byKey(const Key('bottom-nav-/products')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom-nav-/products')));
    await tester.pumpAndSettle();

    expect(find.text('Etalase Produk'), findsOneWidget);
    expect(find.text('Tambah Produk'), findsNothing);
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

  testWidgets('logout asks confirmation and redirects to login',
      (tester) async {
    final authController = FakeLogoutAuthController();
    await pumpApp(tester, authController: authController);

    await tester.tap(find.byKey(const Key('bottom-nav-/more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('more-logout-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('more-logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari aplikasi?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(authController.signOutCallCount, 0);
    expect(find.text('Selamat datang di\nToko Saku!'), findsNothing);

    await tester.tap(find.byKey(const Key('more-logout-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last);
    await tester.pumpAndSettle();

    expect(authController.signOutCallCount, 1);
    expect(find.text('Selamat datang di\nToko Saku!'), findsOneWidget);
  });

  testWidgets(
    'cashier flow enforces registered customer for BON and can checkout',
    (tester) async {
      final container = await pumpApp(tester);

      container.read(posStateProvider).addToCart(
            container.read(posStateProvider).products.first,
          );

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

  testWidgets('cashier info button shows and closes floating explanation', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();

    const explanation =
        'Produk yang dipilih dari halaman Produk akan masuk ke daftar ini.';
    expect(find.text(explanation), findsNothing);

    await tester.tap(find.byTooltip('Lihat penjelasan').first);
    await tester.pumpAndSettle();

    expect(find.text(explanation), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text(explanation), findsNothing);
  });

  testWidgets('cashier has ongoing tab for temporary transactions', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cashier-tab-new')), findsOneWidget);
    expect(find.byKey(const Key('cashier-tab-ongoing')), findsOneWidget);
    expect(find.byKey(const Key('cashier-tab-history')), findsOneWidget);
  });

  testWidgets('nasi paket cart uses move to ongoing button', (tester) async {
    final container = await pumpApp(tester);
    container
        .read(posStateProvider)
        .addToCart(firstNasiPaketProduct(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();

    expect(find.text('Pindah ke Transaksi Sementara'), findsOneWidget);
    expect(find.text('Mulai Pembayaran'), findsNothing);
  });

  testWidgets(
    'moving multiple nasi paket carts from cashier keeps ongoing list visible',
    (tester) async {
      final container = await pumpApp(tester);
      final state = container.read(posStateProvider);
      final product = firstNasiPaketProduct(container);

      await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
      await tester.pumpAndSettle();

      state.addToCart(product);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cashier-checkout-button')));
      await tester.pumpAndSettle();

      final firstPending = container.read(posStateProvider).pendingTransactions;
      expect(firstPending, hasLength(1));
      expect(
        find.byKey(Key('pending-transaction-tile-${firstPending.single.id}')),
        findsOneWidget,
      );
      expect(find.text('Detail Pesanan Berlangsung'), findsNothing);

      await tester.tap(find.byKey(const Key('cashier-tab-new')));
      await tester.pumpAndSettle();

      state.addToCart(product);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cashier-checkout-button')));
      await tester.pumpAndSettle();

      final pendingTransactions =
          container.read(posStateProvider).pendingTransactions;
      expect(pendingTransactions, hasLength(2));
      for (final pending in pendingTransactions) {
        expect(
          find.byKey(Key('pending-transaction-tile-${pending.id}')),
          findsOneWidget,
        );
      }
      expect(find.text('Detail Pesanan Berlangsung'), findsNothing);
    },
  );

  testWidgets(
      'moving nasi paket cart to pending does not checkout or cut stock',
      (tester) async {
    final container = await pumpApp(tester);
    final state = container.read(posStateProvider);
    final product = firstNasiPaketProduct(container);
    final beforeTransactions = state.transactions.length;
    final beforeStock = product.stockQty;

    state.addToCart(product);
    final pending = await state.moveCartToPendingTransaction();
    await tester.pumpAndSettle();

    final updatedProduct = container
        .read(posStateProvider)
        .products
        .firstWhere((item) => item.id == product.id);
    expect(pending.items.single.productId, product.id);
    expect(container.read(posStateProvider).cart, isEmpty);
    expect(container.read(posStateProvider).pendingTransactions, hasLength(1));
    expect(container.read(posStateProvider).transactions.length,
        beforeTransactions);
    expect(updatedProduct.stockQty, beforeStock);
  });

  testWidgets('pending transaction can be opened and completed',
      (tester) async {
    final container = await pumpApp(tester);
    final state = container.read(posStateProvider);
    state.addToCart(firstNasiPaketProduct(container));
    final pending = await state.moveCartToPendingTransaction();
    final beforeTransactions = state.transactions.length;
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cashier-tab-ongoing')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('pending-transaction-tile-${pending.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pesanan Berlangsung'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pending-start-payment-button')));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pending-confirm-checkout-button')));
    await tester.pumpAndSettle();

    expect(container.read(posStateProvider).pendingTransactions, isEmpty);
    expect(container.read(posStateProvider).transactions.length,
        beforeTransactions + 1);
    expect(find.text('Transaksi Berhasil'), findsOneWidget);
  });

  testWidgets('mixed nasi paket pending checkout only cuts stock products',
      (tester) async {
    final container = await pumpApp(tester);
    final state = container.read(posStateProvider);
    final nasiProduct = firstNasiPaketProduct(container);
    final stockProduct = firstStockProduct(container);
    final beforeTransactions = state.transactions.length;

    state.addToCart(nasiProduct);
    state.addToCart(stockProduct);
    final pending = await state.moveCartToPendingTransaction();
    await state.checkoutPendingTransaction(
      pendingTransactionId: pending.id,
      paymentMethod: PaymentMethod.cash,
    );
    await tester.pumpAndSettle();

    final updatedState = container.read(posStateProvider);
    final updatedNasiProduct = updatedState.products.firstWhere(
      (product) => product.id == nasiProduct.id,
    );
    final updatedStockProduct = updatedState.products.firstWhere(
      (product) => product.id == stockProduct.id,
    );
    expect(updatedState.pendingTransactions, isEmpty);
    expect(updatedState.transactions.length, beforeTransactions + 1);
    expect(updatedNasiProduct.stockQty, nasiProduct.stockQty);
    expect(updatedStockProduct.stockQty, stockProduct.stockQty - 1);
  });

  testWidgets('nasi paket uses ready status and empty item cannot be added',
      (tester) async {
    final container = await pumpApp(tester);
    final state = container.read(posStateProvider);
    final nasiCategory = state.categories.firstWhere(
      (category) => category.name.toLowerCase() == 'nasi paket',
    );

    await state.saveProduct(
      name: 'Nasi Kosong Test',
      categoryId: nasiCategory.id,
      sellPrice: 12000,
      costPrice: 7000,
      stockQty: 99,
      minStock: 9,
      unit: 'Porsi',
      isReady: false,
    );
    await tester.pumpAndSettle();

    final product = state.products.firstWhere(
      (item) => item.name == 'Nasi Kosong Test',
    );
    expect(product.stockQty, 0);
    expect(product.minStock, 0);
    expect(product.isReady, isFalse);
    expect(
      () => state.addToCart(product),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('sedang kosong'),
        ),
      ),
    );
  });

  testWidgets('cashier history tab shows transaction code and total amount', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final transaction = await createTransaction(container);
    await tester.pumpAndSettle();

    await openCashierHistoryTab(tester);

    final historyTile =
        find.byKey(Key('transaction-history-tile-${transaction.id}'));
    expect(historyTile, findsOneWidget);
    expect(
      find.descendant(
        of: historyTile,
        matching: find.text(transaction.transactionCode),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: historyTile,
        matching: find.text(AppFormatters.currency(transaction.totalAmount)),
      ),
      findsOneWidget,
    );
    expect(find.text('${transaction.totalQuantity} qty'), findsNothing);
    expect(find.text('${transaction.lineItemCount} jenis item'), findsNothing);
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

    await tester.tap(find.byKey(const Key('bottom-nav-/products')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottom-nav-/cashier')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cashier-checkout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pesanan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cashier-confirm-checkout-button')));
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

    await tester.tap(find.byKey(const Key('bottom-nav-/products')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('products-add-button')));
    await tester.pumpAndSettle();

    expect(find.text('Foto\nproduk'), findsWidgets);

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

    await tester.tap(find.byKey(const Key('bottom-nav-/products')));
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
}

class FakeLogoutAuthController extends AuthController {
  FakeLogoutAuthController() : super.test();

  AuthStatus _status = AuthStatus.authenticated;
  int signOutCallCount = 0;

  @override
  AuthStatus get status => _status;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
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

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  @override
  Future<bool> authenticate({String reason = ''}) async => true;

  @override
  Future<bool> isBiometricAvailable() async => false;
}
