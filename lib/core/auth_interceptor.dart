import 'dart:async';

import 'package:alessio_test_task/auth/session.dart';
import 'package:alessio_test_task/core/api_client.dart';
import 'package:alessio_test_task/core/token_storage.dart';
import 'package:dio/dio.dart';

const _retriedKey = 'retried';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required TokenStorage storage,
    required void Function() onSignedOut,
  }) : _dio = dio,
       _refreshDio = refreshDio,
       _storage = storage,
       _onSignedOut = onSignedOut;

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final void Function() _onSignedOut;

  Future<Tokens?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _storage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final current = await _storage.read();
    if (err.response?.statusCode != 401 ||
        options.extra[_retriedKey] == true ||
        current == null) {
      return handler.next(err);
    }

    final sentWith = options.headers['Authorization'];
    final alreadyRefreshed = sentWith != 'Bearer ${current.accessToken}';
    final tokens = alreadyRefreshed ? current : await _refresh();
    if (tokens == null) {
      await _storage.clear();
      _onSignedOut();
      return handler.next(err);
    }

    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<Tokens?> _refresh() {
    return _refreshing ??= _requestTokens().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<Tokens?> _requestTokens() async {
    final current = await _storage.read();
    if (current == null) return null;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': current.refreshToken,
          'expiresInMins': tokenLifetimeMins,
        },
      );
      final tokens = Tokens.fromJson(response.data!);
      await _storage.write(tokens);
      return tokens;
    } on DioException {
      return null;
    }
  }
}
