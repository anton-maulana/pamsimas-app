import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pamsimas_app/src/core/services/api_client.dart';

class UploadResponse {
  final int id;
  final String filePath;
  
  const UploadResponse({required this.id, required this.filePath});
  
  factory UploadResponse.fromJson(Map<String, dynamic> json) => UploadResponse(
    id: json['id'] as int,
    filePath: json['file_path'] as String,
  );
}

class ImageService {
  static ImageService? _instance;
  static ImageService get instance => _instance ??= ImageService._(ApiClient.instance.dio);

  final Dio _dio;

  ImageService._(this._dio);

  Future<UploadResponse> uploadImage(File file) async {
    try {
      final fileName = file.path.split('/').last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/images/upload',
        data: formData,
      );

      return UploadResponse.fromJson(response.data!);
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail is String) {
           throw Exception(detail);
        }
      }
      throw Exception('Gagal mengupload gambar');
    }
  }
}
