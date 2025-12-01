import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provides a simple online/offline state using connectivity_plus and a
/// lightweight DNS lookup to verify real internet access.
class NetworkService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<ConnectivityResult>? _sub;

  NetworkService() {
    _init();
  }

  void _init() async {
    // initial state
    _isOnline = await _checkInternet();
    notifyListeners();

    // listen for connectivity changes and verify real internet access
    // Debounce rapid changes
    Timer? _debounce;
    _sub = Connectivity().onConnectivityChanged.listen((result) async {
      // If there's no connectivity reported, set offline immediately
      if (result == ConnectivityResult.none) {
        if (_isOnline) {
          _isOnline = false;
          notifyListeners();
        }
        return;
      }

      // For other connectivity types (wifi/mobile), verify internet access
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        final online = await _checkInternet();
        if (online != _isOnline) {
          _isOnline = online;
          notifyListeners();
        }
      });
    });
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
