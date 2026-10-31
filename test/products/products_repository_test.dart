import 'dart:convert';
import 'dart:typed_data';

import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.body);

  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProductsRepository repositoryReturning(Object body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = StubAdapter(body);
  return ProductsRepository(dio);
}

void main() {
  const minimal = {
    'id': 1,
    'title': 'Mascara',
    'price': 9.99,
    'thumbnail': 'https://example.com/1.png',
  };

  test('optional fields fall back to defaults', () {
    final product = Product.fromJson(minimal);

    expect(product.brand, isNull);
    expect(product.images, isEmpty);
    expect(product.stock, 0);
    expect(product.hasDiscount, isFalse);
    expect(product.returnPolicy, isEmpty);
  });

  test('fetchPage parses a valid response', () async {
    final repository = repositoryReturning({
      'products': [minimal],
      'total': 1,
    });

    final page = await repository.fetchPage(skip: 0);

    expect(page.products.single.title, 'Mascara');
    expect(page.total, 1);
  });

  test('fetchPage turns a malformed response into an ApiException', () async {
    final repository = repositoryReturning({
      'products': [
        {'id': 1},
      ],
      'total': 1,
    });

    await expectLater(
      repository.fetchPage(skip: 0),
      throwsA(isA<ApiException>()),
    );
  });

  test('fetchOne turns a malformed response into an ApiException', () async {
    final repository = repositoryReturning({'id': 1});

    await expectLater(repository.fetchOne(1), throwsA(isA<ApiException>()));
  });
}
