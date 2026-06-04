import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';
import 'package:pamsimas_app/src/core/models/payment_model.dart';

// ─── Payment Service ──────────────────────────────────────────────────────────

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance =>
      _instance ??= PaymentService._(ApiClient.instance.dio);

  final Dio _dio;

  PaymentService._(this._dio);

  Future<List<PaymentRead>> getPaymentsByBill(int billId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: {'bill_id': billId},
      );
      final data = response.data?['data'] as List?;
      if (data == null) return [];
      return data.map((p) => PaymentRead.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal memuat pembayaran');
    }
  }

  Future<PaymentRead> create(PaymentCreate request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payments',
        data: request.toJson(),
      );
      return PaymentRead.fromJson(response.data!);
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal mencatat pembayaran');
    }
  }

  Future<void> createCumulative({
    required int customerId,
    required double amountPaid,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/payments/cumulative',
        data: {
          'customer_id': customerId,
          'amount_paid': amountPaid,
          'payment_method': paymentMethod,
          if (referenceNumber != null) 'reference_number': referenceNumber,
          if (notes != null) 'notes': notes,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal mencatat pembayaran kumulatif');
    }
  }

  Future<double> getTotalIncome({int? month, int? year}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payments/stats/income',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return (response.data?['total_income'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) throw Exception(detail);
      }
      throw Exception('Gagal memuat statistik pendapatan');
    }
  }
}
