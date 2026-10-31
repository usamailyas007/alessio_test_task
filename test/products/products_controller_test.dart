import 'dart:async';

import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/products_controller.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures.dart';

ProductPage page({required int from, required int count, required int total}) {
  return ProductPage(
    products: [for (var i = from; i < from + count; i++) product(i)],
    total: total,
  );
}

const offline = ApiException(ApiErrorKind.offline, 'No internet connection.');

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockProductsRepository repository;
  late ProviderContainer container;

  ProductsState read() => container.read(productsControllerProvider);
  ProductsController controller() =>
      container.read(productsControllerProvider.notifier);

  Future<void> start() async {
    container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    )..listen(productsControllerProvider, (_, _) {});
    await settle();
  }

  setUp(() => repository = MockProductsRepository());

  tearDown(() => container.dispose());

  test('first page loads', () async {
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 45));

    await start();

    expect(read().isLoading, isFalse);
    expect(read().items, hasLength(20));
    expect(read().total, 45);
    expect(read().error, isNull);
  });

  test('loadMore appends and stops at total', () async {
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 25));
    when(
      () => repository.fetchPage(skip: 20),
    ).thenAnswer((_) async => page(from: 20, count: 5, total: 25));
    await start();

    await controller().loadMore();
    await controller().loadMore();

    expect(read().items, hasLength(25));
    expect(read().items.last.id, 24);
    expect(read().hasMore, isFalse);
    verify(() => repository.fetchPage(skip: 20)).called(1);
  });

  test('duplicate loadMore calls are ignored', () async {
    final second = Completer<ProductPage>();
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 40));
    when(() => repository.fetchPage(skip: 20)).thenAnswer((_) => second.future);
    await start();

    final first = controller().loadMore();
    final duplicate = controller().loadMore();
    expect(read().isLoadingMore, isTrue);
    second.complete(page(from: 20, count: 20, total: 40));
    await Future.wait([first, duplicate]);

    expect(read().items, hasLength(40));
    verify(() => repository.fetchPage(skip: 20)).called(1);
  });

  test('first load error can be retried', () async {
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) => Future.error(offline));
    await start();

    expect(read().error, offline);
    expect(read().items, isEmpty);

    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 20));
    await controller().loadFirstPage();

    expect(read().error, isNull);
    expect(read().items, hasLength(20));
  });

  test('refresh wins over a load-more still in flight', () async {
    final slow = Completer<ProductPage>();
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 40));
    when(() => repository.fetchPage(skip: 20)).thenAnswer((_) => slow.future);
    await start();

    final more = controller().loadMore();
    await controller().refresh();
    slow.complete(page(from: 20, count: 20, total: 40));
    await more;

    expect(read().items, hasLength(20));
    expect(read().isLoadingMore, isFalse);
  });

  test('load-more error keeps items and can be retried', () async {
    when(
      () => repository.fetchPage(skip: 0),
    ).thenAnswer((_) async => page(from: 0, count: 20, total: 40));
    when(
      () => repository.fetchPage(skip: 20),
    ).thenAnswer((_) => Future.error(offline));
    await start();

    await controller().loadMore();

    expect(read().error, offline);
    expect(read().items, hasLength(20));

    when(
      () => repository.fetchPage(skip: 20),
    ).thenAnswer((_) async => page(from: 20, count: 20, total: 40));
    await controller().loadMore();

    expect(read().error, isNull);
    expect(read().items, hasLength(40));
  });
}
