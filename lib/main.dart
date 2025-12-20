import 'config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/network_service.dart';
import 'screens/splash/splash_screen.dart';
import 'core/widgets/app_update_wrapper.dart';
import 'core/services/auth_service.dart';
import 'core/utils/globals.dart';
import 'screens/auth/login_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Create a default TextTheme or customize your own
  final TextTheme _textTheme = Typography.blackMountainView;

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(_textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Builder(builder: (context) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'GMDCRR',
          theme: materialTheme.light(),
          darkTheme: materialTheme.dark(),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
          builder: (context, child) {
            // Show an offline banner when NetworkService reports offline.
            return AppUpdateWrapper(
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  // Consumer rebuilds the banner whenever NetworkService notifies
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Consumer<NetworkService>(
                        builder: (context, svc, _) {
                          if (svc.isOnline) return const SizedBox.shrink();
                          return Material(
                            color: Colors.red.shade700,
                            elevation: 4,
                            child: SafeArea(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.signal_wifi_off, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No internet connection',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
