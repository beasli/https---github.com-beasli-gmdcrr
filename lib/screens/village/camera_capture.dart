import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cams;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
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
      final bytes = await file.readAsBytes();
      // capture location (may fail on web or if permission denied)
      double? lat, lng;
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        // ignore geolocation errors, return null coords
      }
      if (!mounted) return;
      Navigator.of(context).pop({'path': file.path, 'bytes': bytes, 'lat': lat, 'lng': lng});
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
      body: CameraPreview(_ctrl!),
      floatingActionButton: _isTakingPicture ? const CircularProgressIndicator() : FloatingActionButton(
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
