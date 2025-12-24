import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_db.dart';
import '../../core/services/village_service.dart';
import '../auth/login_screen.dart';
import '../family/family_survey_list.dart';
import '../family/family_survey_service.dart';
import '../village/local_entries.dart';
import '../village/village_form.dart';

/// The main landing page of the application.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  bool _syncCompleted = false;
  List<String> _syncErrors = [];
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Check for local data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncLocalData();
    });
  }

  Future<void> _checkAndSyncLocalData() async {
    if (_isSyncing) return;

    final localDb = LocalDb();
    
    // Fetch pending surveys
    List<Map<String, dynamic>> pendingFamily = [];
    List<Map<String, dynamic>> pendingVillage = [];

    try {
      pendingFamily = await localDb.pendingFamilySurveys();
    } catch (e) {
      print('Error fetching pending family surveys: $e');
    }

    try {
      // Assuming pendingVillageSurveys exists in LocalDb
      pendingVillage = await localDb.pendingVillageSurveys();
    } catch (e) {
      print('Error fetching pending village surveys: $e');
    }

    if (pendingFamily.isEmpty && pendingVillage.isEmpty) {
      return;
    }

    // Block screen and start sync
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Found pending data. Syncing...';
      _syncCompleted = false;
      _syncErrors = [];
    });

    await _performSync(pendingFamily, pendingVillage);
  }

  Future<void> _performSync(
      List<Map<String, dynamic>> familySurveys, List<Map<String, dynamic>> villageSurveys) async {
    final familyService = FamilySurveyService();
    final villageService = VillageService();
    final localDb = LocalDb();
    final errors = <String>[];

    // Sync Family Surveys
    for (var item in familySurveys) {
      try {
        final data = jsonDecode(item['payload']);
        final serverId = data['family']?['id'];
        final headName = data['members']?[0]?['name'] ?? 'Unknown';

        if (!mounted) return;
        setState(() => _statusMessage = 'Syncing Family Survey: $headName');

        final result = await familyService.submitSurvey(data, familySurveyId: serverId);
        if (result['success'] == true) {
          await localDb.deleteFamilySurvey(item['id']);
        } else {
          errors.add('Family Survey ($headName): Upload failed');
        }
      } catch (e) {
        errors.add('Family Survey ID ${item['id']}: ${e.toString()}');
      }
    }

    // Sync Village Surveys
    for (var item in villageSurveys) {
      try {
        final data = jsonDecode(item['payload']);
        // Assuming village name is in the payload
        final villageName = data['village']?['name'] ?? 'Unknown';
        
        if (!mounted) return;
        setState(() => _statusMessage = 'Syncing Village Survey: $villageName');

        // Assuming VillageService has a submitSurvey method similar to FamilySurveyService
        final result = await villageService.submitSurvey(data);
        if (result['success'] == true) {
          await localDb.deleteVillageSurvey(item['id']);
        } else {
          errors.add('Village Survey ($villageName): Upload failed');
        }
      } catch (e) {
        errors.add('Village Survey ID ${item['id']}: ${e.toString()}');
      }
    }

    if (!mounted) return;
    setState(() {
      _syncCompleted = true;
      _syncErrors = errors;
      if (errors.isEmpty) {
        _statusMessage = 'All data synced successfully!';
      } else {
        _statusMessage = 'Sync completed with errors.';
      }
    });

    // If successful, auto-dismiss after a delay
    if (errors.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _handleSyncManually() {
    setState(() {
      _isSyncing = false;
    });
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalEntriesPage())).then((_) => _checkAndSyncLocalData());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSyncing) return false; // Prevent exit during sync
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit the application?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text("Home")),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    child: const Text("Village Survey"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VillageFormPage())).then((_) => _checkAndSyncLocalData());
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    child: const Text("Family Survey"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilySurveyListPage())).then((_) => _checkAndSyncLocalData());
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    child: const Text("Pending Entries"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalEntriesPage())).then((_) => _checkAndSyncLocalData());
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    child: const Text("Logout"),
                    onPressed: () async {
                      await AuthService().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false, // Remove all previous routes
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isSyncing) _buildSyncOverlay(),
        ],
      ),
    );
  }

  Widget _buildSyncOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_syncCompleted) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Sync in Process',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(_statusMessage, textAlign: TextAlign.center),
                ] else if (_syncErrors.isEmpty) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Sync Successful',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_statusMessage, textAlign: TextAlign.center),
                ] else ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Sync Failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _syncErrors
                            .map((e) => Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  color: Colors.red.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(e, style: const TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleSyncManually,
                    child: const Text('Sync Manually'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}