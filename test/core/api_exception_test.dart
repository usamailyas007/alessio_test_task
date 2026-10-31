import 'package:alessio_test_task/core/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException failure(DioExceptionType type, {int? status, Object? data}) {
  final options = RequestOptions(path: '/products');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  test('timeouts are reported as timeout', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(ApiException.from(failure(type)).kind, ApiErrorKind.timeout);
    }
  });

  test('connection errors are reported as offline', () {
    final error = ApiException.from(failure(DioExceptionType.connectionError));

    expect(error.kind, ApiErrorKind.offline);
  });

  test('401 uses the message sent by the server', () {
    final error = ApiException.from(
      failure(
        DioExceptionType.badResponse,
        status: 401,
        data: {'message': 'Invalid credentials'},
      ),
    );

    expect(error.kind, ApiErrorKind.unauthorized);
    expect(error.message, 'Invalid credentials');
  });

  test('500 without a body falls back to a generic message', () {
    final error = ApiException.from(
      failure(DioExceptionType.badResponse, status: 500),
    );

    expect(error.kind, ApiErrorKind.server);
    expect(error.message, contains('500'));
  });

  test('anything else is unknown', () {
    expect(ApiException.from(StateError('x')).kind, ApiErrorKind.unknown);
    expect(
      ApiException.from(failure(DioExceptionType.cancel)).kind,
      ApiErrorKind.unknown,
    );
  });
}
