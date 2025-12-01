import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../core/config/env.dart';
import '../../core/services/auth_service.dart';
import '../village/village_form.dart';
import '../village/local_entries.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Prefill test credentials in debug/testing mode only
    if (AppConfig.currentEnvironment != Environment.production) {
      _usernameCtrl.text = 'jon@gmail.com';
      _passwordCtrl.text = 'Jondoe123@';
    }
  }

  void _doLogin() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  // Authenticate via API
  final authService = AuthService();
  final token = await authService.login(_usernameCtrl.text, _passwordCtrl.text);
  developer.log('Login token: $token', name: 'auth');
  if (token == 'true') {
    // Save token, navigate to Home
    // For now, in-memory - later use shared_preferences
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } else {
    setState(() {
      _errorMessage = token;
      _loading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 4, 156, 90))),
                        )
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dummy home screen—replace later with your main menu/dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text("Village Survey"),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VillageFormPage()));
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text("Pending Entries"),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalEntriesPage()));
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text("Logout"),
              onPressed: () async {
                await AuthService().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
