import 'dart:convert';
import 'dart:typed_data';

import 'package:alessio_test_task/auth/session.dart';
import 'package:alessio_test_task/core/auth_interceptor.dart';
import 'package:alessio_test_task/core/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage(this.tokens);

  Tokens? tokens;

  @override
  Future<Tokens?> read() async => tokens;

  @override
  Future<void> write(Tokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.path} ${options.headers['Authorization']}');
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MemoryTokenStorage storage;
  late FakeAdapter api;
  late FakeAdapter refresh;
  late Dio dio;
  var signedOut = 0;

  void build({required ResponseBody Function(RequestOptions) onRefresh}) {
    api = FakeAdapter(
      (options) => options.headers['Authorization'] == 'Bearer new'
          ? jsonBody({'ok': true}, 200)
          : jsonBody({'message': 'Token expired'}, 401),
    );
    refresh = FakeAdapter(onRefresh);
    final base = BaseOptions(baseUrl: 'https://test.local');
    dio = Dio(base)..httpClientAdapter = api;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        refreshDio: Dio(base)..httpClientAdapter = refresh,
        storage: storage,
        onSignedOut: () => signedOut++,
      ),
    );
  }

  ResponseBody refreshed(RequestOptions _) {
    return jsonBody({'accessToken': 'new', 'refreshToken': 'refresh-2'}, 200);
  }

  setUp(() {
    signedOut = 0;
    storage = MemoryTokenStorage(
      const Tokens(accessToken: 'old', refreshToken: 'refresh-1'),
    );
  });

  test('401 triggers one refresh and one retry', () async {
    build(onRefresh: refreshed);

    final response = await dio.get<dynamic>('/products');

    expect(response.statusCode, 200);
    expect(api.calls, ['/products Bearer old', '/products Bearer new']);
    expect(refresh.calls, hasLength(1));
    expect(storage.tokens?.accessToken, 'new');
    expect(storage.tokens?.refreshToken, 'refresh-2');
    expect(signedOut, 0);
  });

  test('concurrent 401s share a single refresh', () async {
    build(onRefresh: refreshed);

    final responses = await Future.wait([
      dio.get<dynamic>('/products'),
      dio.get<dynamic>('/auth/me'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(refresh.calls, hasLength(1));
  });

  test('failed refresh clears tokens and signs out', () async {
    build(onRefresh: (_) => jsonBody({'message': 'Invalid token'}, 401));

    await expectLater(
      dio.get<dynamic>('/products'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(storage.tokens, isNull);
    expect(signedOut, 1);
    expect(api.calls, ['/products Bearer old']);
  });
}
