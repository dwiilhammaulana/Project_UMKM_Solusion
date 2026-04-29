import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../shared/auth/auth_controller.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/common_widgets.dart';

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
        if (auth.pendingVerificationEmail != null && location != '/verify-email') {
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

      if (isAuthRoute || isLoadingRoute || isOnboardingRoute) {
        return '/dashboard';
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
        ],
      ),
    ],
  );
});

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingState(label: 'Menyiapkan sesi dan profil toko...'),
    );
  }
}
