import 'dart:async';

import 'package:alessio_test_task/auth/auth_controller.dart';
import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/product_list_page.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures.dart';

class SignedOutAuth extends AuthController {
  @override
  AuthState build() => const SignedOut();
}

void main() {
  late MockProductsRepository repository;

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsRepositoryProvider.overrideWithValue(repository),
          authControllerProvider.overrideWith(SignedOutAuth.new),
        ],
        child: const MaterialApp(home: ProductListPage()),
      ),
    );
  }

  setUp(() => repository = MockProductsRepository());

  testWidgets('shows the skeleton while the first page loads', (tester) async {
    final pending = Completer<ProductPage>();
    when(() => repository.fetchPage(skip: 0)).thenAnswer((_) => pending.future);

    await pumpPage(tester);

    expect(find.bySemanticsLabel('Loading products'), findsOneWidget);
  });

  testWidgets('shows products once loaded', (tester) async {
    when(() => repository.fetchPage(skip: 0)).thenAnswer(
      (_) async => ProductPage(products: [product(1), product(2)], total: 2),
    );

    await pumpPage(tester);
    await tester.pump();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => const ProductPage(products: [], total: 0));

    await pumpPage(tester);
    await tester.pump();

    expect(find.text('No products to show.'), findsOneWidget);
  });

  testWidgets('shows the error state and retries', (tester) async {
    when(() => repository.fetchPage(skip: 0)).thenAnswer(
      (_) => Future.error(
        const ApiException(ApiErrorKind.offline, 'No internet connection.'),
      ),
    );
    await pumpPage(tester);
    await tester.pump();
    expect(find.text('No internet connection.'), findsOneWidget);

    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => ProductPage(products: [product(1)], total: 1));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Product 1'), findsOneWidget);
  });
}
