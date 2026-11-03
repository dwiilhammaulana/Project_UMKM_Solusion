import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warung_kopi_pos/features/auth/login_screen.dart';
import 'package:warung_kopi_pos/features/auth/signup_screen.dart';
import 'package:warung_kopi_pos/shared/theme/app_theme.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(360, 640)]) {
    testWidgets('login and register fit ${size.width.toInt()}px screens',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final screen in [
        (widget: const LoginScreen(), action: 'Masuk dengan Google'),
        (widget: const SignupScreen(), action: 'Daftar dengan Google'),
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(theme: AppTheme.lightTheme, home: screen.widget),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          const Color(0xFFF4F9F8),
        );

        await tester.ensureVisible(find.text(screen.action));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final password = find.byType(TextFormField).last;
        final passwordField = find.descendant(
          of: password,
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
        await tester.tap(find.byTooltip('Lihat password'));
        await tester.pump();
        expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      }
    });
  }
}
