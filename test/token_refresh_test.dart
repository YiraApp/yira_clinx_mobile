// When the access token expires, every call a screen sends at that moment is refused together.
// They must share one token renewal and each be retried, instead of all but one landing on
// Session Expired.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/error_interceptor/error_interceptor.dart';
import 'package:yiraclinics/core/error_interceptor/token_refresh_gate.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';

/// A server whose valid token is "new"; anything else is refused with 401.
class _FakeServer implements HttpClientAdapter {
  int renewals = 0;
  bool renewalWorks = true;
  bool refuseEvenNewToken = false;

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.endsWith('/auth/refresh')) {
      renewals++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return renewalWorks
          ? _json({'status': true, 'data': {'accessToken': 'new', 'refreshToken': 'refresh-2'}}, 200)
          : _json({'status': false, 'message': 'Refresh token expired'}, 401);
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final auth = options.headers['Authorization']?.toString();
    if (auth == 'Bearer new' && !refuseEvenNewToken) return _json({'status': true, 'data': options.path}, 200);
    return _json({'status': false, 'message': 'Token expired'}, 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeServer server;
  late Dio api;

  void signIn(String accessToken) {
    GlobalSession.instance.userNotifier.value = LoginEntity(
      status: true,
      data: DataEntity(id: 'doctor-1', accessToken: accessToken, refreshToken: 'refresh-1'),
    );
  }

  Future<Object> call(String path, String token) => api
      .get(path, options: Options(headers: {'Authorization': 'Bearer $token'}))
      .then<Object>((r) => r.statusCode!, onError: (Object e) => e is DioException ? (e.response?.statusCode ?? -1) : -1);

  setUp(() {
    server = _FakeServer();
    Dio client() => Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server;
    ErrorInterceptor.refreshClient = client;
    api = client()..interceptors.add(ErrorInterceptor(showSuccessSnack: false));
    signIn('old');
  });

  test('five calls refused together renew the token once and all succeed', () async {
    final results = await Future.wait([for (var i = 0; i < 5; i++) call('/v1/api/screen/$i', 'old')]);
    expect(results, everyElement(200));
    expect(server.renewals, 1);
    expect(GlobalSession.instance.userNotifier.value?.data?.accessToken, 'new');
    expect(GlobalSession.instance.userNotifier.value?.data?.refreshToken, 'refresh-2');
  });

  test('a call refused after the token was already renewed is retried without renewing again', () async {
    signIn('new');
    expect(await call('/v1/api/late', 'old'), 200);
    expect(server.renewals, 0);
  });

  test('when renewal fails, every refused call fails and the renewal is tried only once', () async {
    server.renewalWorks = false;
    final results = await Future.wait([for (var i = 0; i < 4; i++) call('/v1/api/screen/$i', 'old')]);
    expect(results, everyElement(401));
    expect(server.renewals, 1);
  });

  test('a call still refused with the new token is not renewed again (no loop)', () async {
    server.refuseEvenNewToken = true;
    expect(await call('/v1/api/forbidden', 'old'), 401);
    expect(server.renewals, 1);
  });

  group('TokenRefreshGate', () {
    test('waiting callers share the running renewal', () async {
      final gate = TokenRefreshGate();
      var renewals = 0;
      final done = Completer<String?>();
      Future<String?> renew() {
        renewals++;
        return done.future;
      }

      final waiting = [
        for (var i = 0; i < 3; i++) gate.freshToken(sentToken: 'old', currentToken: 'old', renew: renew),
      ];
      done.complete('new');
      expect(await Future.wait(waiting), ['new', 'new', 'new']);
      expect(renewals, 1);
    });

    test('a failed renewal can be tried again later', () async {
      final gate = TokenRefreshGate();
      expect(await gate.freshToken(sentToken: 'old', currentToken: 'old', renew: () async => throw Exception('offline')), isNull);
      expect(await gate.freshToken(sentToken: 'old', currentToken: 'old', renew: () async => 'new'), 'new');
    });
  });
}
