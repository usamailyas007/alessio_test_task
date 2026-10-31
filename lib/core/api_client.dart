import 'package:alessio_test_task/auth/auth_controller.dart';
import 'package:alessio_test_task/core/auth_interceptor.dart';
import 'package:alessio_test_task/core/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = 'https://dummyjson.com';
const _timeout = Duration(seconds: 15);
const tokenLifetimeMins = 30;

BaseOptions get apiOptions => BaseOptions(
  baseUrl: _baseUrl,
  connectTimeout: _timeout,
  sendTimeout: _timeout,
  receiveTimeout: _timeout,
  headers: {'Accept': 'application/json'},
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(apiOptions);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      refreshDio: Dio(apiOptions),
      storage: ref.watch(tokenStorageProvider),
      onSignedOut: () => ref.read(authControllerProvider.notifier).expire(),
    ),
  );
  return dio;
});
