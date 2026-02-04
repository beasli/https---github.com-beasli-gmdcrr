import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/env.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_db.dart';
import '../../core/services/location_service.dart';
import '../../core/services/village_service.dart';
import '../auth/login_screen.dart';
import '../family/family_survey_list.dart';
import '../family/family_survey_service.dart';
import '../family/local_survey_service.dart';
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
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  String _appVersion = '';
  String? _villageName;
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    // Check for local data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncLocalData();
    });
    _loadAppVersion();
    _startTimer();
    _loadVillageName();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVillageName() async {
    final data = await LocalSurveyService.instance.getLastSavedVillage();
    if (data != null && mounted) {
      setState(() {
        _villageName = data['data']?['village']?['name'];
      });
    }
  }

  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() async {
    final remaining = await AuthService().getRemainingSessionTime();
    if (mounted) {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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

  Future<void> _handleUpdateLocation() async {
    if (_isUpdatingLocation) return;
    setState(() => _isUpdatingLocation = true);

    try {
      Position? pos;
      // For staging/dev, use a fixed location to simplify testing
      if (AppConfig.currentEnvironment != Environment.production) {
        pos = Position(
          latitude: 21.6701,
          longitude: 72.2319,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      } else {
        pos = await LocationService.getPositionWithFallback();
      }

      if (pos != null) {
        final nearby = await VillageService().fetchNearbyByLatLng(pos.latitude, pos.longitude);
        if (nearby != null) {
          // Inject the captured location into the payload so it is persisted
          if (nearby['data'] is Map) {
            final dataMap = nearby['data'] as Map;
            dataMap['user_lat'] = pos.latitude;
            dataMap['user_lon'] = pos.longitude;
          }
          await LocalSurveyService.instance.saveVillage(nearby);
          if (mounted) {
            setState(() {
              _villageName = nearby['data']?['village']?['name'];
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No village found nearby', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not determine location', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSyncing) return false; // Prevent exit during sync
        final shouldPop = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
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
          ),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
        return shouldPop ?? false;
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.90,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(5, 30, 30, 0.4), // Glassmorphism dark bg
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF36D1A8).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Area ---
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Welcome to your\nVillage Survey.",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFD0D7DD), // Light grey
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFF36D1A8), size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _villageName ?? "Unknown Village",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: "You are in ${_villageName ?? 'Unknown Village'}. Please turn on the internet and tap Sync to update the village name.",
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: IconButton(
                              icon: _isUpdatingLocation
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.sync, color: Colors.white),
                              onPressed: _isUpdatingLocation ? null : _handleUpdateLocation,
                              tooltip: 'Update Location',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32), // Spacing between header and grid

                      // --- Tiles Grid ---
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.0, // Square tiles
                          children: [
                            _buildDashboardTile(
                              icon: Icons.home_outlined,
                              label: "Village Survey",
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VillageFormPage())).then((_) => _checkAndSyncLocalData());
                              },
                            ),
                            _buildDashboardTile(
                              icon: Icons.people_outline,
                              label: "Family Survey",
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilySurveyListPage())).then((_) => _checkAndSyncLocalData());
                              },
                            ),
                            // _buildDashboardTile(
                            //   icon: Icons.access_time,
                            //   label: "Pending Entries",
                            //   onTap: () {
                            //     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalEntriesPage())).then((_) => _checkAndSyncLocalData());
                            //   },
                            // ),
                            _buildDashboardTile(
                              icon: Icons.power_settings_new,
                              label: "Logout",
                              onTap: () async {
                                final shouldLogout = await showGeneralDialog<bool>(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  transitionDuration: const Duration(milliseconds: 250),
                                  pageBuilder: (context, animation, secondaryAnimation) => BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text('Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                );

                                if (shouldLogout == true) {
                                  await AuthService().logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 16),
                      // Text(
                      //   "Auto logout in: ${_formatDuration(_remainingTime)}",
                      //   style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                      // ),
                      if (_appVersion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _appVersion,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSyncing) _buildSyncOverlay(),
        ],
      ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: isHighlighted 
            ? const Color(0xFFF6A623).withOpacity(0.3) 
            : const Color(0xFF00C46A).withOpacity(0.3),
        highlightColor: isHighlighted 
            ? const Color(0xFFF6A623).withOpacity(0.1) 
            : const Color(0xFF00C46A).withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Highlighted tile gets a gradient, others get dark translucent fill
            gradient: isHighlighted
                ? const LinearGradient(
                    colors: [Color(0xFFF6A623), Color(0xFFD88A16)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isHighlighted 
                ? null 
                : const Color.fromRGBO(20, 40, 40, 0.6), // Dark grey/green 70-80% opacity equivalent
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFF6A623).withOpacity(0.8)
                  : const Color(0xFF36D1A8).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isSyncing = false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _handleSyncManually,
                        child: const Text('Sync Manually'),
                      ),
                    ],
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