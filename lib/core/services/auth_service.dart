import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../utils/globals.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> checkLoginStatus() async {
    final token = await getToken();
    // Check if token exists and is not empty. Add expiry logic here if needed.
    _isAuthenticated = token != null && token.isNotEmpty;
    notifyListeners();
    return _isAuthenticated;
  }

  /// Logs in the user. Returns null if successful, or an error message string.
  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '$kApiBaseUrl/auth/login',
        data: {'email': username, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Adjust key based on your actual API response (e.g. 'token', 'access_token', or data['token'])
        final token = response.data['accessToken'] ?? response.data['data']?['accessToken'];
        
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          _isAuthenticated = true;
          notifyListeners();
          return null; // Success
        }
      }
      return 'Invalid credentials ${response.statusCode}';
    } on DioException catch (e) {
      print('Login error: ${e.response?.data ?? e.message}');
      return e.response?.data?['message'] ?? 'Login failed. Please check your connection.';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    await logout();
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}