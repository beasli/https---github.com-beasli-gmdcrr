import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/env.dart';
import '../../core/services/local_db.dart';
import '../../core/services/village_service.dart';
import 'family_survey_form.dart';
import 'family_survey_service.dart';

/// A page to display a list of family surveys for the user's current village.
class FamilySurveyListPage extends StatefulWidget {
  const FamilySurveyListPage({super.key});

  @override
  State<FamilySurveyListPage> createState() => _FamilySurveyListPageState();
}

class _FamilySurveyListPageState extends State<FamilySurveyListPage> with SingleTickerProviderStateMixin {
  final VillageService _villageService = VillageService();
  final FamilySurveyService _surveyService = FamilySurveyService();
  final LocalDb _localDb = LocalDb();

  TabController? _tabController;
  Future<List<dynamic>>? _remoteSurveysFuture;
  Future<List<dynamic>>? _localSurveysFuture;
  String _loadingMessage = 'Determining your location...';
  String? _villageName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Start the process of finding the village and loading surveys.
    _initializeAndLoadSurveys();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Fetches locally saved surveys and formats them for the list.
  Future<List<dynamic>> _fetchLocalSurveys() async {
    final localMaps = await _localDb.pendingFamilySurveys();
    return localMaps.map((map) {
      final surveyPayload = jsonDecode(map['payload'] as String);
      final localId = map['id'] as int?; // Use the ID from the local DB row
      final headName = surveyPayload['members']?[0]?['name'] ?? 'N/A';
      final houseNo = surveyPayload['family']?['house_no'] ?? 'N/A';

      return {
        'id': localId, // This will be the temporary negative ID for new drafts
        'head_name': headName,
        'house_no': houseNo,
        'status': 'local_draft', // Custom status for UI
        'is_local': true,
        'survey_data': surveyPayload, // Pass the full data for opening the form
      };
    }).toList();
  }

  /// Determines location, finds the nearby village, and then fetches surveys.
  Future<void> _initializeAndLoadSurveys() async {
    if (!mounted) return;

    double lat, lon;

    // For staging/dev, use a fixed location to simplify testing
    if (AppConfig.currentEnvironment != Environment.production) {
      lat = 21.6701;
      lon = 72.2319;
    } else {
      try {
        final position = await _determinePosition();
        lat = position.latitude;
        lon = position.longitude;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loadingMessage = e.toString();
          _remoteSurveysFuture = Future.value([]); // Set to empty to stop loading
          _localSurveysFuture = Future.value([]);
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loadingMessage = 'Finding nearby village...');

    final villageData = await _villageService.fetchNearbyByLatLng(lat, lon);
    if (mounted && villageData?['data']?['village'] != null) {
      final village = villageData!['data']['village'];
      final villageId = village['id'] as int;
      final villageName = village['name'] as String;
      setState(() {
        _villageName = villageName;
        _loadingMessage = 'Loading surveys for $_villageName...';
        // Fetch both local and remote surveys
        _remoteSurveysFuture = _surveyService.fetchUserSurveysByVillage(villageId);
        _localSurveysFuture = _fetchLocalSurveys();
      });
    } else if (mounted) {
      setState(() {
        _loadingMessage = 'Could not find a nearby village.\nPlease try refreshing.';
        _remoteSurveysFuture = Future.value([]); // Set to empty to stop loading
        _localSurveysFuture = Future.value([]);
      });
    }
  }

  /// Refreshes the data by re-running the initialization process.
  void _refreshData() {
    setState(() {
      _remoteSurveysFuture = null; // Reset futures to show loading indicator
      _localSurveysFuture = null;
      _loadingMessage = 'Determining your location...';
      _villageName = null;
    });
    _initializeAndLoadSurveys();
  }

  /// Navigates to the form to create a new survey and reloads the list upon return.
  Future<void> _navigateToSurveyForm({int? surveyId, Map<String, dynamic>? surveyData}) async {
    // For local drafts, we pass the full data object to avoid a network call.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FamilySurveyFormPage(familySurveyId: surveyId),
        // Pass the full survey data if it's a local draft.
        settings: surveyData != null
            ? RouteSettings(arguments: surveyData)
            : null,
      ),
    );
    // If the form was popped with a 'true' result, it means data was saved.
    if (result == true) {
      _refreshData(); // Reload the list to show the new/updated survey
    }
  }

  /// Attempts to sync a single local draft to the server.
  Future<void> _syncLocalSurvey(int localId, Map<String, dynamic> surveyData) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Syncing survey..."),
          ],
        ),
      ),
    );

    // The server ID for an update is inside the payload.
    final int? serverId = surveyData['family']?['id'];

    final result = await _surveyService.submitSurvey(surveyData, familySurveyId: serverId);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close the loading dialog

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey synced successfully!'), backgroundColor: Colors.green),
      );
      // On success, delete the local draft.
      await _localDb.deleteFamilySurvey(localId);
      _refreshData(); // Refresh the lists
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please edit and submit manually.'), backgroundColor: Colors.red),
      );
    }
  }

  /// Shows a confirmation dialog and deletes a local draft if confirmed.
  Future<void> _deleteLocalSurvey(int localId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('Are you sure you want to permanently delete this local draft? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _localDb.deleteFamilySurvey(localId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local draft deleted.'), backgroundColor: Colors.green),
      );
      _refreshData();
    }
  }
  /// Returns a color based on the survey status.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'local_draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Determines the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied. Please enable them in app settings.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_villageName ?? 'Family Surveys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not yet implemented.')),
              );
            },
            tooltip: 'Search Surveys',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh List',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Server Surveys'),
            Tab(text: 'Local Drafts'),
          ],
        ),
      ),
      body: (_remoteSurveysFuture == null || _localSurveysFuture == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage)
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Server Surveys Tab
                _buildSurveyListView(
                    _remoteSurveysFuture, 'No surveys found on the server.'),
                // Local Drafts Tab
                _buildSurveyListView(
                    _localSurveysFuture, 'No local drafts found.'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _navigateToSurveyForm(), // Call without a surveyId for a new survey
        tooltip: 'New Survey',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// A reusable widget to build a list of surveys from a future.
  Widget _buildSurveyListView(
      Future<List<dynamic>>? future, String noDataMessage) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_loadingMessage)
              ]));
        }
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text(noDataMessage, textAlign: TextAlign.center));
        }

        final surveys = snapshot.data!;
        return ListView.builder(
          itemCount: surveys.length,
          itemBuilder: (context, index) {
            final survey = surveys[index];
            final familyId = survey['id'] as int?;
            final headName = survey['head_name'] as String? ?? 'N/A';
            final status = survey['status'] as String? ?? 'Unknown';
            final houseNo = survey['house_no'] as String? ?? 'N/A';
            final isLocal = survey['is_local'] as bool? ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status),
                      child: Text(
                          headName.isNotEmpty ? headName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(headName),
                    subtitle: Text(isLocal
                        ? 'Un-synced Draft • House No: $houseNo'
                        : 'ID: $familyId • House No: $houseNo'),
                    trailing: isLocal
                        ? null // Buttons are moved below
                        : Chip(
                            label: Text(status, style: const TextStyle(color: Colors.white)),
                            backgroundColor: _getStatusColor(status),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                    onTap: () => _navigateToSurveyForm(
                      surveyId: familyId,
                      surveyData: isLocal ? survey['survey_data'] : null,
                    ),
                  ),
                  if (isLocal)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () {
                              if (familyId != null) _deleteLocalSurvey(familyId);
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync'),
                            onPressed: () {
                              if (familyId != null) _syncLocalSurvey(familyId, survey['survey_data']);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () => _navigateToSurveyForm(surveyId: familyId, surveyData: survey['survey_data']),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}