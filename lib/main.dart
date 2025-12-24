import 'config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/network_service.dart';
import 'screens/splash/splash_screen.dart';
import 'core/widgets/app_update_wrapper.dart';
import 'core/services/auth_service.dart';
import 'core/utils/globals.dart';
import 'screens/auth/login_screen.dart';
import 'core/widgets/offline_banner.dart';


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
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: OfflineBanner(),
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
