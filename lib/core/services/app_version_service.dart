import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dio_client.dart';

class AppVersionService {
  // Use the centralized DioClient
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>?> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final String version = packageInfo.version;
      final String platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await _dio.post(
        'https://api-gmdc-lams.lgeom.com/v1/app/version/check',
        data: {
          'platform': platform,
          'version': version,
        },
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error checking app version: $e');
    }
    return null;
  }
}
