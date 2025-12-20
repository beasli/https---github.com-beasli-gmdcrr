import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../core/config/api.dart';
import '../../core/services/dio_client.dart';

/// Service class for handling family survey related API calls.
class FamilySurveyService {
  final Dio _dio = DioClient.instance;
  final String _baseUrl = kApiBaseUrl;

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
      final response = await _dio.post(
        '$_baseUrl/family-survey/upload-document',
        data: formData,
        options: Options(headers: {'accept': '*/*'}),
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
  /// If [familySurveyId] is provided, it updates an existing survey (PUT).
  /// Otherwise, it creates a new one (POST).
  /// Returns true on success, false on failure.
  Future<Map<String, dynamic>> submitSurvey(Map<String, dynamic> surveyData, {int? familySurveyId}) async {
    try {
      final headers = <String, dynamic>{
        'accept': '*/*',
        'Content-Type': 'application/json',
      };

      Response response;
      if (familySurveyId != null) {
        // This is an update (PUT request)
        final updatePayload = {
          "family_id": familySurveyId,
          ...surveyData,
        };
        response = await _dio.put(
          '$_baseUrl/family-survey/$familySurveyId',
          data: updatePayload,
          options: Options(headers: headers),
        );
      } else {
        // This is a new submission (POST request)
        response = await _dio.post(
          '$_baseUrl/family-survey',
          data: surveyData,
          options: Options(headers: headers),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {'success': false};
    } on DioException catch (e) {
      print('Error submitting survey: ${e.response?.data ?? e.message}');
      return {'success': false};
    }
  }

  /// Fetches the details of a single family survey by its ID.
  Future<Map<String, dynamic>?> fetchSurveyById(int id) async {
    try {
      final headers = <String, dynamic>{'accept': '*/*'};

      final response = await _dio.get('$_baseUrl/family-survey/$id', options: Options(headers: headers));

      if (response.statusCode == 200 && response.data?['data']?['family_survey'] != null) {
        return response.data['data']['family_survey'] as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      print('Error fetching survey by ID: ${e.response?.data ?? e.message}');
    }
    return null;
  }

  /// Fetches a list of family surveys for the logged-in user, optionally filtered by village ID.
  ///
  /// Takes a [villageId].
  /// Returns a list of survey data on success, or an empty list on failure.
  Future<List<dynamic>> fetchUserSurveysByVillage(int villageId) async {
    try {
      final headers = <String, dynamic>{'accept': '*/*'};
  
      final response = await _dio.get(
        '$_baseUrl/family-survey/user',
        queryParameters: {
          'villageIds': villageId,
          'page': 1,
          'limit': 100, // Fetching up to 100 surveys, adjust if pagination is needed
          'sort-by': 'Newest First',
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data?['data']?['family_surveys'] != null) {
        return response.data['data']['family_surveys'] as List<dynamic>;
      }
    } on DioException catch (e) {
      print('Error fetching user surveys by village: ${e.response?.data ?? e.message}');
    }
    return []; // Return an empty list on failure or if data is not in the expected format.
  }
}