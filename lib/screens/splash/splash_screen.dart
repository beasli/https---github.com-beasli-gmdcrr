import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../home/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    // Optional: Keep the splash screen visible for a moment (e.g., 2 seconds)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showLocationServiceDialog();
      return;
    }

    final permission = await LocationService.requestPermission();

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (mounted) _checkAuthAndNavigate();
    } else {
      if (mounted) _showPermissionDialog(permission);
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services (GPS) to continue.'),
        actions: [
          TextButton(onPressed: () => Geolocator.openLocationSettings(), child: const Text('Settings')),
          TextButton(
              onPressed: () { Navigator.pop(ctx); _ensureLocationPermission(); },
              child: const Text('Retry')),
        ],
      ),
    );
  }

  void _showPermissionDialog(LocationPermission status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(status == LocationPermission.deniedForever
            ? 'Location permission is permanently denied. Please enable it in app settings to continue.'
            : 'This app requires location permission to function. Please grant permission.'),
        actions: [
          if (status == LocationPermission.deniedForever)
            TextButton(onPressed: () => Geolocator.openAppSettings(), child: const Text('Settings')),
          TextButton(
              onPressed: () { Navigator.pop(ctx); _ensureLocationPermission(); },
              child: const Text('Retry')),
        ],
      ),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.checkLoginStatus();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomePage() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
