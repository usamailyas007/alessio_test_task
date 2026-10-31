import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/product_detail_page.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures.dart';

const offline = ApiException(ApiErrorKind.offline, 'No internet connection.');

void main() {
  late MockProductsRepository repository;

  Future<void> pumpPage(WidgetTester tester, {bool withInitial = true}) {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [productsRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: ProductDetailPage(
            id: 1,
            initial: withInitial ? product(1) : null,
          ),
        ),
      ),
    );
  }

  setUp(() => repository = MockProductsRepository());

  testWidgets('keeps the list data and offers a retry when refetch fails', (
    tester,
  ) async {
    when(() => repository.fetchOne(1)).thenAnswer((_) => Future.error(offline));

    await pumpPage(tester);
    await tester.pump();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.textContaining('Could not refresh'), findsOneWidget);

    when(() => repository.fetchOne(1)).thenAnswer((_) async => product(1));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Could not refresh'), findsNothing);
  });

  testWidgets('shows a full error when there is nothing to show', (
    tester,
  ) async {
    when(() => repository.fetchOne(1)).thenAnswer((_) => Future.error(offline));

    await pumpPage(tester, withInitial: false);
    await tester.pump();

    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.text('Product 1'), findsNothing);
  });
}
