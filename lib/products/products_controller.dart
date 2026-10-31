import 'dart:async';

import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsState {
  const ProductsState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Product> items;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final ApiException? error;

  bool get hasMore => items.length < total;
}

class ProductsController extends Notifier<ProductsState> {
  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  var _generation = 0;

  @override
  ProductsState build() {
    unawaited(_fetchFirstPage());
    return const ProductsState(isLoading: true);
  }

  Future<void> loadFirstPage() {
    if (state.isLoading) return Future.value();
    state = const ProductsState(isLoading: true);
    return _fetchFirstPage();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.isLoading || current.isLoadingMore || !current.hasMore) return;

    final generation = _generation;
    state = ProductsState(
      items: current.items,
      total: current.total,
      isLoadingMore: true,
    );
    try {
      final page = await _repository.fetchPage(skip: current.items.length);
      if (generation != _generation) return;
      state = ProductsState(
        items: [...current.items, ...page.products],
        total: page.total,
      );
    } on ApiException catch (error) {
      if (generation != _generation) return;
      state = ProductsState(
        items: current.items,
        total: current.total,
        error: error,
      );
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    final generation = _generation;
    final page = await _repository.fetchPage(skip: 0);
    if (generation != _generation) return;
    _generation++;
    state = ProductsState(items: page.products, total: page.total);
  }

  Future<void> _fetchFirstPage() async {
    final generation = ++_generation;
    try {
      final page = await _repository.fetchPage(skip: 0);
      if (generation != _generation) return;
      state = ProductsState(items: page.products, total: page.total);
    } on ApiException catch (error) {
      if (generation != _generation) return;
      state = ProductsState(error: error);
    }
  }
}

final productsControllerProvider =
    NotifierProvider.autoDispose<ProductsController, ProductsState>(
      ProductsController.new,
    );
