import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/models/petugas_model.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';

// ─── Petugas Service ──────────────────────────────────────────────────────────

/// Handles all CRUD operations for petugas (officers) against the backend
  /// `/officers` and `/user/{user_id}` endpoints.
class PetugasService {
  static PetugasService? _instance;
  static PetugasService get instance =>
      _instance ??= PetugasService._(ApiClient.instance.dio);

  final Dio _dio;

  PetugasService._(this._dio);

  /// Fetches a paginated list of petugas.
  ///
  /// Returns raw list from `data` field of the paginated response.
  Future<List<PetugasModel>> list({int page = 1, int itemsPerPage = 100, String? rt, String? rw}) async {
    try {
      final url = '/user/officers?page=$page&items_per_page=$itemsPerPage' +
          (rt != null ? '&rt=$rt' : '') +
          (rw != null ? '&rw=$rw' : '');
      print('[PetugasService] GET $url');

      final response = await _dio.get<Map<String, dynamic>>(url);

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');

      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      final result = rawList
          .map((e) => PetugasModel.fromJson(e as Map<String, dynamic>))
          .toList();

      print('[PetugasService] Parsed ${result.length} petugas');
      return result;
    } catch (e) {
      print('[PetugasService] ERROR in list(): $e');
      rethrow;
    }
  }

  /// Creates a new petugas account.
  Future<PetugasModel> create(PetugasCreateRequest request) async {
    try {
      final url = '/user/officers';
      final body = request.toJson();

      print('[PetugasService] POST $url');
      print('[PetugasService] Request Body: $body');
      print('[PetugasService] Headers: ${_dio.options.headers}');

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
      );

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');

      return PetugasModel.fromJson(response.data!);
    } on DioException catch (e) {
      print('[PetugasService] ERROR in create(): $e');
      print('[PetugasService] DioException Status: ${e.response?.statusCode}');
      print('[PetugasService] DioException Response: ${e.response?.data}');
      
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          throw Exception(detail);
        } else if (detail is List && detail.isNotEmpty) {
          final firstError = detail[0];
          if (firstError is Map && firstError.containsKey('msg')) {
             throw Exception(firstError['msg']);
          }
        }
      }
      throw Exception(e.message ?? 'Gagal membuat petugas. Periksa kembali data Anda.');
    } catch (e) {
      print('[PetugasService] ERROR in create(): $e');
      rethrow;
    }
  }

  /// Updates an existing petugas identified by [userId].
  Future<void> update(int userId, PetugasUpdateRequest request) async {
    try {
      final url = '/user/officers/$userId';
      final body = request.toJson();

      print('[PetugasService] PATCH $url');
      print('[PetugasService] Request Body: $body');
      print('[PetugasService] Headers: ${_dio.options.headers}');

      final response = await _dio.patch<dynamic>(
        url,
        data: body,
      );

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');
    } catch (e) {
      print('[PetugasService] ERROR in update(): $e');
      if (e is DioException) {
        print('[PetugasService] DioException Status: ${e.response?.statusCode}');
        print('[PetugasService] DioException Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Soft-deletes a petugas identified by [userId].
  Future<void> delete(int userId) async {
    try {
      final url = '/user/officers/$userId';

      print('[PetugasService] DELETE $url');
      print('[PetugasService] Headers: ${_dio.options.headers}');

      final response = await _dio.delete<dynamic>(url);

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');
    } catch (e) {
      print('[PetugasService] ERROR in delete(): $e');
      if (e is DioException) {
        print('[PetugasService] DioException Status: ${e.response?.statusCode}');
        print('[PetugasService] DioException Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Fetches the number of customers assigned to a petugas.
  Future<int> customerCount(int userId) async {
    try {
      final url = '/user/officers/$userId/customers/count';

      print('[PetugasService] GET $url');
      print('[PetugasService] Headers: ${_dio.options.headers}');

      final response = await _dio.get<Map<String, dynamic>>(url);

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');

      return (response.data?['customer_count'] as int?) ?? 0;
    } catch (e) {
      print('[PetugasService] ERROR in customerCount(): $e');
      if (e is DioException) {
        print('[PetugasService] DioException Status: ${e.response?.statusCode}');
        print('[PetugasService] DioException Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Resets a petugas password.
  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      final url = '/user/officers/$userId/reset-password';
      final body = {'new_password': newPassword};

      print('[PetugasService] PATCH $url');
      print('[PetugasService] Request Body: $body');
      print('[PetugasService] Headers: ${_dio.options.headers}');

      final response = await _dio.patch<dynamic>(
        url,
        data: body,
      );

      print('[PetugasService] Response Status: ${response.statusCode}');
      print('[PetugasService] Response Data: ${response.data}');
    } catch (e) {
      print('[PetugasService] ERROR in resetPassword(): $e');
      if (e is DioException) {
        print('[PetugasService] DioException Status: ${e.response?.statusCode}');
        print('[PetugasService] DioException Response: ${e.response?.data}');
      }
      rethrow;
    }
  }
}

