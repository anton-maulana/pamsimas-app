import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pamsimas_app/src/core/models/auth_model.dart';
import 'package:pamsimas_app/src/core/models/login_model.dart';

// ─── Auth Service ─────────────────────────────────────────────────────────────

class AuthService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';
  static const String _keyAccess = 'access_token';
  static const String _keyRefresh = 'refresh_token';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  
  // Cache the decoded token so it's globally available 
  Map<String, dynamic>? _decodedToken;

  AuthService._internal() : _storage = const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );
  }
  
  Map<String, dynamic>? get currentUser => _decodedToken;

  /// Login dengan [username] dan [password], menyimpan token secara aman.
  Future<AuthToken> login(LoginModel loginModel) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {
        'username': loginModel.username,
        'password': loginModel.password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType, // penting!
      ),
    );

    final token = AuthToken.fromJson(response.data!);
    await _saveTokens(token);
    _decodeAndCacheToken(token.accessToken);
    return token;
  }

  /// Memperbarui access token menggunakan refresh token yang tersimpan.
  /// Mengirim refresh_token via request body (form-urlencoded).
  /// Mengembalikan access token baru.
  Future<String> refreshToken() async {
    final refresh = await _storage.read(key: _keyRefresh);
    if (refresh == null || refresh.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/refresh'),
        error: 'No refresh token available',
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/refresh',
      data: {'refresh_token': refresh},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    // /refresh hanya mengembalikan access_token (tanpa refresh_token baru)
    final newAccessToken = response.data!['access_token'] as String;
    await _storage.write(key: _keyAccess, value: newAccessToken);
    _decodeAndCacheToken(newAccessToken);
    return newAccessToken;
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _keyAccess);
    if (token != null && _decodedToken == null) {
      _decodeAndCacheToken(token);
    }
    return token;
  }
  
  void _decodeAndCacheToken(String token) {
    try {
      _decodedToken = JwtDecoder.decode(token);
      print('[AuthService] Decoded Token: $_decodedToken');
    } catch (e) {
      print('[AuthService] Error decoding token: $e');
      _decodedToken = null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserFromServer() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;
      
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      // Update local profile data if needed
      return response.data;
    } catch (e) {
      print('[AuthService] Error fetching profile: $e');
      return _decodedToken; // Fallback to token data
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    _decodedToken = null;
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
    ]);
  }

  Future<void> _saveTokens(AuthToken token) async {
    await Future.wait([
      _storage.write(key: _keyAccess, value: token.accessToken),
      _storage.write(key: _keyRefresh, value: token.refreshToken),
    ]);
  }
}
