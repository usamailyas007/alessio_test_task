import 'package:alessio_test_task/core/api_client.dart';
import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const productsPageSize = 20;

class ProductPage {
  const ProductPage({required this.products, required this.total});

  final List<Product> products;
  final int total;
}

class ProductsRepository {
  const ProductsRepository(this._dio);

  final Dio _dio;

  Future<ProductPage> fetchPage({required int skip}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {'limit': productsPageSize, 'skip': skip},
      );
      final json = response.data!;
      return ProductPage(
        products: (json['products'] as List<dynamic>)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
      );
    } on Object catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<Product> fetchOne(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$id');
      return Product.fromJson(response.data!);
    } on Object catch (error) {
      throw ApiException.from(error);
    }
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(dioProvider)),
);
