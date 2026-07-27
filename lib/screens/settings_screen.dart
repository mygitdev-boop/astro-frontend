import 'package:flutter/material.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.themeMode,
              builder: (context, mode, _) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: mode,
                      activeColor: AppTheme.accentOrange,
                      onChanged: (m) => ThemeController.setMode(m!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: mode,
                      activeColor: AppTheme.accentOrange,
                      onChanged: (m) => ThemeController.setMode(m!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Follow system'),
                      value: ThemeMode.system,
                      groupValue: mode,
                      activeColor: AppTheme.accentOrange,
                      onChanged: (m) => ThemeController.setMode(m!),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    // TODO: link to your actual hosted privacy policy once you have one --
                    // required for Play Store submission.
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms & conditions'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    // TODO: link to your actual hosted terms once you have them.
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  subtitle: Text('Astro BhavishyaAI v1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
