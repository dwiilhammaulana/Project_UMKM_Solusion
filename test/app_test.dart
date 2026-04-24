import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warung_kopi_pos/app/app.dart';
import 'package:warung_kopi_pos/shared/database/app_database.dart';
import 'package:warung_kopi_pos/shared/state/app_state.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
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
        ],
        child: const WarungKopiApp(),
      ),
    );
    for (var i = 0; i < 30; i++) {
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
        return;
      }
    }

    final visibleTexts = find.byType(Text).evaluate().map((element) {
      final widget = element.widget as Text;
      return widget.data ?? widget.textSpan?.toPlainText() ?? '<rich-text>';
    }).join(' | ');
    fail('Dashboard never appeared. Visible texts: $visibleTexts');
  }

  testWidgets('app opens dashboard and can navigate from drawer', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Warung Kopi Pertigaan Jati'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-produk')));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Produk'), findsOneWidget);
  });

  testWidgets(
    'cashier flow enforces registered customer for BON and can checkout',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('app-drawer-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drawer-kasir')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('payment-bon')));
      await tester.tap(find.byKey(const Key('payment-bon')));
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const Key('cashier-checkout-button')));
      await tester.tap(find.byKey(const Key('cashier-checkout-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Transaksi BON wajib memilih pelanggan'),
        findsOneWidget,
      );

      await tester
          .ensureVisible(find.byKey(const Key('cashier-customer-search')));
      await tester.enterText(
        find.byKey(const Key('cashier-customer-search')),
        'Pak Slamet',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Pak Slamet').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cashier-checkout-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Transaksi BON Tersimpan'), findsOneWidget);
    },
  );

  testWidgets('customers search works and customer form opens', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('app-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-pelanggan')));
    await tester.pumpAndSettle();

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

  testWidgets('debt payment updates ui flow', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('app-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-bon/utang')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Bayar Cicilan').first);
    await tester.tap(find.text('Bayar Cicilan').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('debt-payment-amount')),
      '10000',
    );
    await tester.tap(find.text('Simpan Pembayaran'));
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Bon / Utang'), findsOneWidget);
  });
}
