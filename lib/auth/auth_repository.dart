import 'package:alessio_test_task/auth/session.dart';
import 'package:alessio_test_task/core/api_client.dart';
import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/core/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  const AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<User> signIn(String username, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'expiresInMins': tokenLifetimeMins,
        },
      );
      final json = response.data!;
      await _storage.write(Tokens.fromJson(json));
      return User.fromJson(json);
    } on Object catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<User?> restore() async {
    if (await _storage.read() == null) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> signOut() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
