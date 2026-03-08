import 'package:dio/dio.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';

/// Dio interceptor: adds Bearer token, retries on 401 after refresh.
class AuthInterceptor extends QueuedInterceptor {
  final TokenManager _tokenManager;
  final SessionManager _sessionManager;
  final Dio _dio;

  AuthInterceptor({
    required TokenManager tokenManager,
    required SessionManager sessionManager,
    required Dio dio,
  })  : _tokenManager = tokenManager,
        _sessionManager = sessionManager,
        _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final extra = err.requestOptions.extra;
    if (extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    final newToken = await _sessionManager.refreshToken();
    if (newToken == null) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;
    opts.headers['Authorization'] = 'Bearer $newToken';
    opts.extra['_retried'] = true;

    try {
      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
