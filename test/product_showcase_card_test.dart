import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warung_kopi_pos/features/products/widgets/product_showcase_card.dart';
import 'package:warung_kopi_pos/shared/models/app_models.dart';

void main() {
  testWidgets('compact product card fits a stock forecast', (tester) async {
    const product = Product(
      id: 'prd-forecast',
      name: 'Kopi Susu Gula Aren Spesial',
      categoryId: 'cat-produk-kemasan',
      sellPrice: 16000,
      costPrice: 7000,
      stockQty: 2,
      minStock: 4,
      unit: 'Pack',
      rackLocation: 'Etalase dekat pintu depan',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 154,
              height: 320,
              child: ProductShowcaseCard(
                product: product,
                categoryName: 'produk kemasan',
                imageHeight: 120,
                count: 2,
                forecastFuture: Future.value(const {'prd-forecast': 12.0}),
                onAdd: () {},
                onManage: () {},
                onLongPress: () {},
                showManageActions: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Butuh ±12 besok'), findsOneWidget);
    expect(find.text('Tambah (2)'), findsOneWidget);
  });
}
