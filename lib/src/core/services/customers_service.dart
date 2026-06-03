import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';

// ─── Customers Service ────────────────────────────────────────────────────────

class CustomersService {
  static CustomersService? _instance;
  static CustomersService get instance =>
      _instance ??= CustomersService._(ApiClient.instance.dio);

  final Dio _dio;

  CustomersService._(this._dio);

  /// Mengambil daftar pelanggan dengan filter opsional.
  ///
  /// Mendukung paginasi melalui [page] dan [itemsPerPage].
  /// Backend mengembalikan `{ "data": [...], "total": N }`.
  Future<List<Customer>> list({
    String? search,
    String? rt,
    String? rw,
    String? status,
    int? officerId,
    String? meterNumber,
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      '/customers',
      queryParameters: {
        'page': page,
        'items_per_page': itemsPerPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (rt != null && rt != 'Semua') 'rt': rt,
        if (rw != null && rw != 'Semua') 'rw': rw,
        if (status != null && status != 'Semua') 'status': status.toUpperCase(),
        if (officerId != null) 'officer_id': officerId,
        if (meterNumber != null && meterNumber.isNotEmpty) 'meter_number': meterNumber,
      },
    );
    // Backend returns a plain JSON array
    List<dynamic> rawList;
    if (response.data is List) {
      rawList = response.data as List<dynamic>;
    } else if (response.data is Map) {
      rawList = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    } else {
      rawList = [];
    }
    return rawList
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mengambil detail satu pelanggan berdasarkan [id].
  Future<Customer> get(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/customers/$id');
    return Customer.fromJson(response.data!);
  }

  /// Membuat pelanggan baru.
  Future<Customer> create(CustomerRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customers',
      data: request.toJson(),
    );
    return Customer.fromJson(response.data!);
  }

  /// Memperbarui data pelanggan dengan [id].
  Future<Customer> update(String id, CustomerRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/customers/$id',
      data: request.toJson(),
    );
    return Customer.fromJson(response.data!);
  }

  /// Menghapus pelanggan dengan [id].
  Future<void> delete(String id) async {
    await _dio.delete<void>('/customers/$id');
  }
}
