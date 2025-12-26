import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../utils/open_url.dart';

class AppUpdateWrapper extends StatefulWidget {
  final Widget child;
  const AppUpdateWrapper({super.key, required this.child});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  bool _isBlocked = false;
  String? _blockingMessage;
  String? _storeUrl;
  bool _isForceUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    return; // Temporarily disable version checks
    final service = AppVersionService();
    final data = await service.checkVersion();

    if (!mounted || data == null) return;

    final bool allow = data['allow'] ?? true;
    final bool forceUpdate = data['force_update'] ?? false;
    final bool updateAvailable = data['update_available'] ?? false;
    final String? storeUrl = data['store_url'];
    final String? latestVersion = data['latest_version'];

    // 1. Check allow (Highest priority: if false, app must NOT be usable)
    if (!allow) {
      setState(() {
        _isBlocked = true;
        _blockingMessage = 'This version of the application is no longer supported.';
        _storeUrl = null; 
        _isForceUpdate = false;
      });
      return;
    }

    // 2. Check force_update (Mandatory update)
    if (forceUpdate) {
      setState(() {
        _isBlocked = true;
        _blockingMessage = 'A new version ($latestVersion) is available. Update is mandatory.';
        _storeUrl = storeUrl;
        _isForceUpdate = true;
      });
      return;
    }

    // 3. Check update_available (Optional update)
    if (updateAvailable) {
      _showOptionalUpdateDialog(latestVersion, storeUrl);
    }
  }

  void _showOptionalUpdateDialog(String? version, String? url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('Version ${version ?? 'New'} is available. Would you like to update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              if (url != null) openUrl(url);
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isForceUpdate ? Icons.system_update : Icons.block,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _isForceUpdate ? 'Update Required' : 'Access Denied',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _blockingMessage ?? 'Please update the app to continue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_storeUrl != null)
                  ElevatedButton(
                    onPressed: () => openUrl(_storeUrl!),
                    child: const Text('Update Now'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
