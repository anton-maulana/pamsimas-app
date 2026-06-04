import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';
import 'package:pamsimas_app/src/core/models/meter_reading_model.dart';

// ─── Meter Reading Service ──────────────────────────────────────────────────

class MeterReadingService {
  static MeterReadingService? _instance;
  static MeterReadingService get instance =>
      _instance ??= MeterReadingService._(ApiClient.instance.dio);

  final Dio _dio;

  MeterReadingService._(this._dio);

  Future<MeterReading> create(MeterReadingRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/meter-readings',
        data: request.toJson(),
      );
      return MeterReading.fromJson(response.data!);
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) {
           throw Exception(detail);
        }
      }
      throw Exception('Gagal menyimpan data catat meter');
    }
  }
}