import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';
import 'package:pamsimas_app/src/core/models/bill_model.dart';

// ─── Bill Service ─────────────────────────────────────────────────────────────

class BillService {
  static BillService? _instance;
  static BillService get instance =>
      _instance ??= BillService._(ApiClient.instance.dio);

  final Dio _dio;

  BillService._(this._dio);

  Future<List<BillRead>> getBillsByCustomer(int customerId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/bills',
        queryParameters: {'customer_id': customerId},
      );
      final data = response.data?['data'] as List?;
      if (data == null) return [];
      return data.map((b) => BillRead.fromJson(b as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal memuat tagihan pelanggan');
    }
  }

  Future<List<BillRead>> list({
    int? customerId,
    String? status,
    int? billingMonth,
    int? billingYear,
    int page = 1,
    int itemsPerPage = 100,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/bills',
        queryParameters: {
          'page': page,
          'items_per_page': itemsPerPage,
          if (customerId != null) 'customer_id': customerId,
          if (status != null && status != 'Semua') 'status': status.toLowerCase() == 'belum bayar' ? 'unpaid' : status.toLowerCase(),
          if (billingMonth != null) 'billing_month': billingMonth,
          if (billingYear != null) 'billing_year': billingYear,
        },
      );
      final data = response.data?['data'] as List?;
      if (data == null) return [];
      return data.map((b) => BillRead.fromJson(b as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal memuat daftar tagihan');
    }
  }

  Future<BillRead> create(BillCreate request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/bills',
        data: request.toJson(),
      );
      return BillRead.fromJson(response.data!);
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal membuat tagihan');
    }
  }
}
