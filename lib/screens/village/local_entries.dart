import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/local_db.dart';
import '../../core/services/village_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/file_image_widget.dart';

class LocalEntriesPage extends StatefulWidget {
  const LocalEntriesPage({super.key});

  @override
  State<LocalEntriesPage> createState() => _LocalEntriesPageState();
}

class _LocalEntriesPageState extends State<LocalEntriesPage> {
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await LocalDb().pendingEntries();
    if (!mounted) return;
    setState(() => _items = rows);
  }

  Future<void> _retry(Map<String, Object?> row) async {
    final id = row['id'] is int ? row['id'] as int : int.tryParse(row['id']?.toString() ?? '') ?? -1;
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid entry id')));
      return;
    }

    dynamic rawPayload = row['payload'];
    Map<String, dynamic>? payload;
    if (rawPayload == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payload')));
      return;
    }
    if (rawPayload is String) {
      try {
        payload = jsonDecode(rawPayload) as Map<String, dynamic>;
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid payload')));
        return;
      }
    } else if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    }

    final imagePath = row['imagePath'] as String?;
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing payload')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload entry'),
        content: const Text('Do you want to upload this pending entry to the server now?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Upload')),
        ],
      ),
    );
    if (confirm != true) return;

    bool ok = false;
    try {
      // Prefer updateSurvey when payload contains a remote survey id
      final directRemoteId = row['remoteSurveyId'] as int?;
      dynamic sidFromPayload = payload['remoteSurveyId'] ?? payload['surveyId'] ?? payload['survey_id'] ?? (payload['attachments'] is Map ? (payload['attachments'] as Map)['survey_id'] : null);
      final remoteIdFromPayload = sidFromPayload != null ? int.tryParse(sidFromPayload.toString()) : null;
      final remoteId = directRemoteId ?? remoteIdFromPayload;
      if (remoteId != null) {
        final token = await AuthService().getToken();
        ok = await VillageService().updateSurvey(remoteId, payload, imagePath, bearerToken: token);
      }
    } catch (e) {
      ok = false;
    }

    if (ok) {
      await LocalDb().deleteEntry(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  Future<void> _delete(int id) async {
    await LocalDb().deleteEntry(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Village Entries')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final r = _items[i];
          return ListTile(
            title: Text('Entry ${r['id']}'),
              subtitle: Text('Created: ${r['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(r['createdAt'] as int).toString() : '-'}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocalEntryDetailPage(entry: r)))),
              IconButton(icon: const Icon(Icons.upload), onPressed: () => _retry(r)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(r['id'] as int)),
            ]),
          );
        },
      ),
    );
  }
}

class LocalEntryDetailPage extends StatelessWidget {
  final Map<String, Object?> entry;
  const LocalEntryDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    dynamic raw = entry['payload'];
    Map<String, dynamic>? payload;
    if (raw is String) {
      try {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        payload = {'raw': raw};
      }
    } else if (raw is Map) {
      payload = Map<String, dynamic>.from(raw);
    }

    final imagePath = entry['imagePath'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('Entry ${entry['id']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imagePath != null) ...[
            Center(child: fileImageWidget(imagePath, height: 200, fit: BoxFit.contain)),
            const SizedBox(height: 12),
          ],
          const Text('Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text(payload != null ? const JsonEncoder.withIndent('  ').convert(payload) : 'No payload'))),
        ]),
      ),
    );
  }
}
