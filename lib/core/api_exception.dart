import 'package:dio/dio.dart';

enum ApiErrorKind { offline, timeout, unauthorized, server, unknown }

class ApiException implements Exception {
  const ApiException(this.kind, this.message);

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return const ApiException(
        ApiErrorKind.unknown,
        'Something went wrong. Please try again.',
      );
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        ApiErrorKind.timeout,
        'The request timed out. Please try again.',
      ),
      DioExceptionType.connectionError => const ApiException(
        ApiErrorKind.offline,
        'No internet connection.',
      ),
      DioExceptionType.badResponse => _fromResponse(error.response),
      _ => const ApiException(
        ApiErrorKind.unknown,
        'Something went wrong. Please try again.',
      ),
    };
  }

  final ApiErrorKind kind;
  final String message;

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;
    final serverMessage = data is Map<String, dynamic>
        ? data['message'] as String?
        : null;

    if (status == 400 || status == 401 || status == 403) {
      return ApiException(
        ApiErrorKind.unauthorized,
        serverMessage ?? 'You are not authorized.',
      );
    }
    return ApiException(
      ApiErrorKind.server,
      serverMessage ?? 'The server returned an error ($status).',
    );
  }

  @override
  String toString() => message;
}
