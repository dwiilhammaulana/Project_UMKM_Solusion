import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/cashier/cashier_screen.dart';
import '../../features/cashier/transaction_detail_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/debts/debt_detail_screen.dart';
import '../../features/debts/debts_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/users/users_screen.dart';
import '../../shared/auth/auth_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' ||
          location == '/signup' ||
          location == '/verify-email';
      final isLoadingRoute = location == '/loading';
      final isOnboardingRoute = location == '/onboarding';

      if (auth.status == AuthStatus.initializing) {
        return isLoadingRoute ? null : '/loading';
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (auth.pendingVerificationEmail != null &&
            location != '/verify-email') {
          return '/verify-email';
        }
        if (isAuthRoute) {
          return null;
        }
        return '/login';
      }

      if (auth.status == AuthStatus.needsOnboarding) {
        return isOnboardingRoute ? null : '/onboarding';
      }

      final homeLocation = auth.isAdmin ? '/dashboard' : '/cashier';
      if (isAuthRoute || isLoadingRoute || isOnboardingRoute) {
        return homeLocation;
      }

      if (!auth.isAdmin && !_isCashierAllowedLocation(location)) {
        return '/cashier';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _RouteLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _authTransitionPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _authTransitionPage(
          state: state,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentLocation: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cashier',
            builder: (context, state) => const CashierScreen(),
            routes: [
              GoRoute(
                path: 'transactions/:transactionId',
                builder: (context, state) => TransactionDetailScreen(
                  transactionId: state.pathParameters['transactionId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
            routes: [
              GoRoute(
                path: ':customerId',
                builder: (context, state) => CustomerDetailScreen(
                  customerId: state.pathParameters['customerId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/debts',
            builder: (context, state) => const DebtsScreen(),
            routes: [
              GoRoute(
                path: ':debtId',
                builder: (context, state) =>
                    DebtDetailScreen(debtId: state.pathParameters['debtId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
        ],
      ),
    ],
  );
});

bool _isCashierAllowedLocation(String location) {
  return location == '/cashier' ||
      location.startsWith('/cashier/transactions/') ||
      location == '/products' ||
      location.startsWith('/products/') ||
      location == '/debts' ||
      location.startsWith('/debts/');
}

CustomTransitionPage<void> _authTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(fade);

      return Stack(
        fit: StackFit.expand,
        children: [
          const _AuthRouteTransitionBackground(),
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _AuthRouteTransitionBackground extends StatelessWidget {
  const _AuthRouteTransitionBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF0E4A43),
        image: DecorationImage(
          image: ResizeImage(
            const AssetImage('bg login.png'),
            height: (size.height * pixelRatio).round(),
          ),
          fit: BoxFit.cover,
          alignment: isKeyboardVisible ? Alignment.topCenter : Alignment.center,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.08),
            BlendMode.darken,
          ),
        ),
      ),
    );
  }
}

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppTheme.deepTeal,
        child: Center(
          child: Lottie.asset(
            'assets/lottie/loading.json',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (_, __, ___) => const CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
