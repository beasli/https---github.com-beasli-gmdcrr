import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      return result.isGranted;
    }
  }

  /// Request camera permission.
  /// Returns true if granted, false otherwise.
  Future<bool> requestCameraPermission() async {
    return _requestPermission(Permission.camera);
  }

  /// Request location permission.
  /// Returns true if granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    return _requestPermission(Permission.locationWhenInUse);
  }

  /// Request both camera and location permissions.
  /// Returns true if both are granted.
  Future<bool> requestAllPermissions() async {
    final permissions = await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();

    return permissions[Permission.camera]!.isGranted &&
           permissions[Permission.locationWhenInUse]!.isGranted;
  }
}