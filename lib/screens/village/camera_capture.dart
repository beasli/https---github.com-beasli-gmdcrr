import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cams;
  bool _isTakingPicture = false;
  Position? _currentPos;
  StreamSubscription<Position>? _posStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _startLocationStream();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    try {
      _cams = await availableCameras();
      if (_cams != null && _cams!.isNotEmpty) {
        _ctrl = CameraController(_cams!.first, ResolutionPreset.medium);
        await _ctrl!.initialize();
        if (!mounted) return;
        setState(() {});
      }
    } catch (e, st) {
      // initialization failed (permissions, no camera, etc.)
      // show error UI by setting controller null and logging
      // ignore logging dependency here; simply set state so build can show error
      if (!mounted) return;
      setState(() { _ctrl = null; });
      debugPrint('Camera init failed: $e\n$st');
    }
  }

  Future<void> _startLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (mounted) setState(() => _currentPos = position);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _ctrl;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePhoto() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized || _isTakingPicture) return;

    // Prevent multiple captures
    if (_ctrl!.value.isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final file = await _ctrl!.takePicture();
      String filePath = file.path;

      if (!kIsWeb) {
        // Ensure file has .jpg extension (only on mobile/desktop where we can rename)
        if (!filePath.toLowerCase().endsWith('.jpg') && !filePath.toLowerCase().endsWith('.jpeg')) {
          final newPath = '$filePath.jpg';
          try {
            await File(filePath).rename(newPath);
            filePath = newPath;
          } catch (e) {
            debugPrint('Error renaming file: $e');
          }
        }
      }

      // capture location (may fail on web or if permission denied)
      double? lat, lng;
      try {
        if (_currentPos != null) {
          lat = _currentPos!.latitude;
          lng = _currentPos!.longitude;
        } else {
          final pos = await Geolocator.getCurrentPosition();
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {
        // ignore geolocation errors, return null coords
      }

      if (!kIsWeb && lat != null && lng != null) {
        try {
          final exif = await Exif.fromPath(filePath);
          await exif.writeAttributes({
            'GPSLatitude': lat.abs(),
            'GPSLatitudeRef': lat >= 0 ? 'N' : 'S',
            'GPSLongitude': lng.abs(),
            'GPSLongitudeRef': lng >= 0 ? 'E' : 'W',
          });
          await exif.close();

          // Verify EXIF data by reading it back
          final verifyExif = await Exif.fromPath(filePath);
          final attributes = await verifyExif.getAttributes();
          debugPrint('Verified EXIF Data: $attributes');
          await verifyExif.close();
        } catch (e) {
          debugPrint('Error writing EXIF: $e');
        }
      }

      Uint8List bytes;
      if (kIsWeb) {
        bytes = await file.readAsBytes();
      } else {
        bytes = await File(filePath).readAsBytes();
      }
      if (!mounted) return;
      Navigator.of(context).pop({'path': filePath, 'bytes': bytes, 'lat': lat, 'lng': lng});
    } on CameraException catch (e, st) {
      debugPrint('Failed to take picture: $e\n$st');
      if (!mounted) return;
      // show a simple snackbar then return to caller with null
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to capture photo')));
      Navigator.of(context).pop(null);
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _posStream?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null) {
      // either still loading or failed to initialize
      return Scaffold(
        appBar: AppBar(title: const Text('Capture Photo')),
        body: const Center(child: Text('Camera not available')),
      );
    }
    if (!_ctrl!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Photo')),
      body: Stack(
        children: [
          CameraPreview(_ctrl!),
          if (_currentPos != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lat: ${_currentPos!.latitude.toStringAsFixed(6)}\nLng: ${_currentPos!.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isTakingPicture ? const CircularProgressIndicator() : FloatingActionButton(
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
