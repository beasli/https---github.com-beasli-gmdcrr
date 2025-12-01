import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:async';

import 'local_db.dart';
import 'village_service.dart';
import 'network_service.dart';
import 'auth_service.dart';

class UploadService {
  final LocalDb _db = LocalDb();
  final VillageService _api = VillageService();
  VoidCallback? _listener;
  NetworkService? _net;

  void start(NetworkService net) {
    _tryPending();
    _listener = () {
      if (net.isOnline) _tryPending();
    };
  net.addListener(_listener!);
  _net = net;
  }

  Future<void> _tryPending() async {
    final pend = await _db.pendingEntries();
    for (final row in pend) {
      final localId = row['id'] as int;
      final remoteId = row['remoteSurveyId'] as int?;
      final rawPayload = row['payload'] as String?;
      final imagePath = row['imagePath'] as String?;

      if (remoteId == null || rawPayload == null) continue;

      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(rawPayload) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final token = await AuthService().getToken();
      final ok = await _api.updateSurvey(remoteId, payload, imagePath, bearerToken: token);
      if (ok) {
        await _db.deleteEntry(localId);
      }
    }
  }

  void dispose() {
    if (_listener != null && _net != null) {
      try {
        _net!.removeListener(_listener!);
      } catch (_) {}
    }
  }
}
