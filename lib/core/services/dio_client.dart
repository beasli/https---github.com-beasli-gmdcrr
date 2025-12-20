import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../utils/globals.dart';
import 'auth_service.dart';

class DioClient {
  static final Dio _dio = Dio();
  static bool _initialized = false;

  static Dio get instance {
    if (!_initialized) {
      _dio.options.baseUrl = kApiBaseUrl;
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              Provider.of<AuthService>(context, listen: false).handleSessionExpired();
            }
          }
          return handler.next(e);
        },
      ));
      _initialized = true;
    }
    return _dio;
  }
}