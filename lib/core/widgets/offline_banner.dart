import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    context.read<NetworkService>().addListener(_resetDismissal);
  }

  @override
  void dispose() {
    context.read<NetworkService>().removeListener(_resetDismissal);
    super.dispose();
  }

  void _resetDismissal() {
    if (context.read<NetworkService>().isOnline && _isDismissed) {
      setState(() => _isDismissed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, svc, _) {
        final show = !svc.isOnline && !_isDismissed;
        return AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(20.0),
                child: Material(
                  color: Colors.red.shade700,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.signal_wifi_off, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'No internet connection',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _isDismissed = true),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}