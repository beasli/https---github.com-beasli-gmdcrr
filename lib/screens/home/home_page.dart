import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../family/family_survey_list.dart';
import '../village/local_entries.dart';
import '../village/village_form.dart';

/// The main landing page of the application.
class HomePage extends StatelessWidget {
  const HomePage({super.key});
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
              child: const Text("Family Survey"),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilySurveyListPage()));
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