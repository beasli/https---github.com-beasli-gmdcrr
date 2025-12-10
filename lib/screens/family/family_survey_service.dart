import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../core/config/api.dart';
import '../../core/services/auth_service.dart';

class FamilySurveyService {
  final Dio _dio = Dio();
  final String _baseUrl = kApiBaseUrl;
  final AuthService _authService = AuthService();

  /// Uploads a single document/image file.
  ///
  /// Takes file [bytes] and the original [filePath] to extract a name.
  /// Returns the remote URL of the uploaded file on success, or null on failure.
  Future<String?> uploadDocument(Uint8List bytes, String filePath) async {
    final fileName = p.basename(filePath);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      final bearerToken = await _authService.getToken();
      final headers = <String, dynamic>{'accept': '*/*'};
      if (bearerToken != null && bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _dio.post(
        '$_baseUrl/family-survey/upload-document',
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 && response.data != null) {
        return response.data['file_name_url'] as String?;
      }
    } on DioException catch (e) {
      print('Error uploading document: ${e.response?.data ?? e.message}');
    }
    return null;
  }

  /// Submits the entire family survey data.
  ///
  /// Takes a [surveyData] map.
  /// Returns true on success, false on failure.
  Future<bool> submitSurvey(Map<String, dynamic> surveyData) async {
    try {
      final bearerToken = await _authService.getToken();
      final headers = <String, dynamic>{
        'accept': '*/*',
        'Content-Type': 'application/json',
      };
      if (bearerToken != null && bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _dio.post('$_baseUrl/family-survey', data: surveyData, options: Options(headers: headers));

      // Assuming 200 or 201 indicates success
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Error submitting survey: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}