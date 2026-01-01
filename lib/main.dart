import 'core/config/app_theme.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {

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
          theme: AppTheme.darkTheme.copyWith(
            canvasColor: const Color(0xFF051E1E),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            canvasColor: const Color(0xFF051E1E),
          ),
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
          builder: (context, child) {
            // Show an offline banner when NetworkService reports offline.
            return Stack(
              children: [
                // 1. Global Background Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF00352F), // Deep teal green
                        Color(0xFF006B57), // Rich emerald green
                        Color(0xFF00171C), // Dark blue-green / charcoal
                      ],
                    ),
                  ),
                ),
                // 2. Subtle Geometric Overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GeometricBackgroundPainter(),
                  ),
                ),
                // 3. App Content (Wrapped in Update Checker)
                Positioned.fill(
                  child: AppUpdateWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                // 4. Offline Banner
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: OfflineBanner(),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw a rounded square top-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.1, 100, 100),
        const Radius.circular(16),
      ),
      paint,
    );

    // Draw a diagonal line
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
