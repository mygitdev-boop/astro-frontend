import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

/// Basic profile screen. Covers the core items from the screen spec
/// (name, birth details summary, language, logout); subscription status,
/// saved reports, and settings are flagged as backlog below.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.accentSaffronLight,
                    child: Icon(Icons.person, color: AppTheme.warning, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserSession.name ?? 'Guest',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          UserSession.phoneNumber ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  trailing: Text(UserSession.languagePref == 'hi' ? 'हिन्दी' : 'English'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: const Text('Moon sign (Rashi)'),
                  trailing: Text(UserSession.moonSignRashi ?? '--'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Subscription'),
                  trailing: Text('Free'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.warning),
              title: const Text('Log out', style: TextStyle(color: AppTheme.warning)),
              onTap: () {
                UserSession.clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
