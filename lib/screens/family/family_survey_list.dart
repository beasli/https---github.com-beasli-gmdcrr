import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/env.dart';
import '../../core/services/village_service.dart';
import 'family_survey_form.dart';
import 'family_survey_service.dart';

/// A page to display a list of family surveys for the user's current village.
class FamilySurveyListPage extends StatefulWidget {
  const FamilySurveyListPage({super.key});

  @override
  State<FamilySurveyListPage> createState() => _FamilySurveyListPageState();
}

class _FamilySurveyListPageState extends State<FamilySurveyListPage> {
  final VillageService _villageService = VillageService();
  final FamilySurveyService _surveyService = FamilySurveyService();

  Future<List<dynamic>>? _surveysFuture;
  String _loadingMessage = 'Determining your location...';
  String? _villageName;

  @override
  void initState() {
    super.initState();
    // Start the process of finding the village and loading surveys.
    _initializeAndLoadSurveys();
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
          _surveysFuture = Future.value([]); // Set to empty to stop loading
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
        _surveysFuture = _surveyService.fetchUserSurveysByVillage(villageId);
      });
    } else if (mounted) {
      setState(() {
        _loadingMessage = 'Could not find a nearby village.\nPlease try refreshing.';
        _surveysFuture = Future.value([]); // Set to empty to stop loading
      });
    }
  }

  /// Refreshes the data by re-running the initialization process.
  void _refreshData() {
    setState(() {
      _surveysFuture = null; // Reset future to show loading indicator
      _loadingMessage = 'Determining your location...';
      _villageName = null;
    });
    _initializeAndLoadSurveys();
  }

  /// Navigates to the form to create a new survey and reloads the list upon return.
  Future<void> _navigateToSurveyForm({int? surveyId}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => FamilySurveyFormPage(familySurveyId: surveyId)),
    );
    // If the form was popped with a 'true' result, it means data was saved.
    if (result == true) {
      _refreshData(); // Reload the list to show the new/updated survey
    }
  }

  /// Returns a color based on the survey status.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.green;
      case 'draft':
        return Colors.orange;
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
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _surveysFuture,
        builder: (context, snapshot) {
          // Show loading indicator and message while waiting for the future
          if (snapshot.connectionState == ConnectionState.waiting || _surveysFuture == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_loadingMessage)],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading surveys: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No surveys found.\nTap the "+" button to create one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final surveys = snapshot.data!;
          return ListView.builder(
            itemCount: surveys.length,
            itemBuilder: (context, index) {
              final survey = surveys[index];
              final familyId = survey['id'] as int? ?? 0;
              final headName = survey['head_name'] as String? ?? 'N/A';
              final status = survey['status'] as String? ?? 'Unknown';
              final houseNo = survey['house_no'] as String? ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Text(headName.isNotEmpty ? headName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(headName),
                  subtitle: Text('ID: $familyId • House No: $houseNo'),
                  trailing: Chip(
                    label: Text(status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: _getStatusColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    _navigateToSurveyForm(surveyId: familyId);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToSurveyForm(), // Call without a surveyId for a new survey
        tooltip: 'New Survey',
        child: const Icon(Icons.add),
      ),
    );
  }
}