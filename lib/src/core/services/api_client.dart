import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';

// ─── API Client ───────────────────────────────────────────────────────────────

class ApiClient {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor(dio));
  }
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('[AuthInterceptor] Token added to request');
      print('[AuthInterceptor] Token (first 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    } else {
      print('[AuthInterceptor] WARNING: No token found!');
    }
    print('[AuthInterceptor] Request URL: ${options.baseUrl}${options.path}');
    print('[AuthInterceptor] Request Method: ${options.method}');
    print('[AuthInterceptor] Request Headers: ${options.headers}');
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('[AuthInterceptor] Error Status: ${err.response?.statusCode}');
    print('[AuthInterceptor] Error Response: ${err.response?.data}');
    print('[AuthInterceptor] Error Message: ${err.message}');
    
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshRequest = err.requestOptions.path.contains('/refresh');

    if (isUnauthorized && !isRefreshRequest && !_isRefreshing) {
      print('[AuthInterceptor] 401 Unauthorized - attempting token refresh');
      _isRefreshing = true;
      try {
        final newToken = await AuthService.instance.refreshToken();
        print('[AuthInterceptor] Token refreshed successfully');
        _isRefreshing = false;
        final opts = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken';
        final response = await _dio.fetch<dynamic>(opts);
        handler.resolve(response);
        return;
      } catch (e) {
        print('[AuthInterceptor] Token refresh failed: $e');
        _isRefreshing = false;
        await AuthService.instance.logout();
      }
    }
    handler.next(err);
  }
}
