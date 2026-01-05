import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../utils/globals.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isAuthenticated = false;
  Timer? _sessionTimer;
  // Check if exp time pending more than "6 days and 23 hour and 55 mintues"
  // Change this to Duration(minutes: 5) on production if needed
  static const Duration minTokenValidity = Duration(days: 0, hours: 0, minutes: 15);

  bool get isAuthenticated => _isAuthenticated;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> checkLoginStatus() async {
    final token = await getToken();
    // Check if token exists and is not empty. Add expiry logic here if needed.
    _isAuthenticated = token != null && token.isNotEmpty;
    if (_isAuthenticated) {
      _startSessionTimer();
    } else {
      _stopSessionTimer();
    }
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
          _startSessionTimer();
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
    _stopSessionTimer();
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
          content: Text('Session expired. Please login again.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> validateSession() async {
    final token = await getToken();
    if (token != null && !isTokenValid(token)) {
      await handleSessionExpired();
    }
  }

  bool isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);
      if (payloadMap is! Map<String, dynamic>) return false;
      final exp = payloadMap['exp'];
      if (exp != null && exp is num) {
        final expiry = DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt());
        final remaining = expiry.difference(DateTime.now());
        print('Token expiry check: $remaining remaining, minimum required: $minTokenValidity');
        if (remaining < minTokenValidity) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Duration> getRemainingSessionTime() async {
    final token = await getToken();
    if (token == null) return Duration.zero;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return Duration.zero;
      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);
      final exp = payloadMap['exp'];
      if (exp != null && exp is num) {
        final expiry = DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt());
        final remaining = expiry.difference(DateTime.now());
        final timeUntilLogout = remaining - minTokenValidity;
        return timeUntilLogout.isNegative ? Duration.zero : timeUntilLogout;
      }
    } catch (_) {}
    return Duration.zero;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
      default: throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }

  void _startSessionTimer() {
    _stopSessionTimer();
    // Check every minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      validateSession();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}