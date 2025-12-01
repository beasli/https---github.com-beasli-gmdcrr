import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  final Dio _dio = Dio();

  Future<String?> login(String username, String password) async {
    const url = 'https://api-gmdc-lams.lgeom.com/v1/auth/login'; // Replace as needed
    try {
      final response = await _dio.post(
        url,
        data: {'email': username, 'password': password},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
     
     if (response.statusCode == 201 && response.data['data']['accessToken'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', response.data['data']['accessToken']);
        return 'true';
      }
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        // Handle common auth errors explicitly
        if (status == 400) {
          return 'Invalid credentials';
        }
        if (status == 401) {
          // Server returns JSON like { message: "Invalid login details", error: "Unauthorized", statusCode: 401 }
          if (data is Map && data['message'] is String) {
            return data['message'] as String;
          }
          return 'Unauthorized';
        }
        // Optionally log response body for other errors
        developer.log('Login error response: ${e.response?.data}', name: 'auth');
      } else {
          developer.log('Login error: $e', name: 'auth');
      }
    }
    return null; 
  }

   // For future API calls: Retrieve token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }

}
