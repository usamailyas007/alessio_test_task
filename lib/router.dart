import 'package:alessio_test_task/auth/auth_controller.dart';
import 'package:alessio_test_task/auth/login_page.dart';
import 'package:alessio_test_task/auth/splash_page.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/product_detail_page.dart';
import 'package:alessio_test_task/products/product_list_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _splash = '/splash';
const _login = '/login';
const _products = '/products';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..listen(authControllerProvider, (_, next) => auth.value = next)
    ..onDispose(auth.dispose);

  final router = GoRouter(
    initialLocation: _splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      return switch (auth.value) {
        AuthLoading() => location == _splash ? null : _splash,
        SignedOut() => location == _login ? null : _login,
        SignedIn() =>
          location == _login || location == _splash ? _products : null,
      };
    },
    routes: [
      GoRoute(path: _splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: _login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: _products,
        builder: (_, _) => const ProductListPage(),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (_, state) =>
                int.tryParse(state.pathParameters['id']!) == null
                ? _products
                : null,
            builder: (_, state) {
              final extra = state.extra;
              return ProductDetailPage(
                id: int.parse(state.pathParameters['id']!),
                initial: extra is Product ? extra : null,
              );
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
