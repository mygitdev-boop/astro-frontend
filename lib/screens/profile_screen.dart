import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'birth_details_screen.dart';
import 'subscription_screen.dart';
import 'settings_screen.dart';
import 'family_profiles_screen.dart';

/// Basic profile screen. Covers the core items from the screen spec
/// (name, birth details summary, language, logout); subscription status,
/// saved reports, and settings are flagged as backlog below.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _updatingLanguage = false;

  Future<void> _openBirthDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BirthDetailsScreen()),
    );
    if (result == true) setState(() {}); // refresh to show the new moon sign
  }

  Future<void> _changeLanguage() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose your language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ListTile(
              title: const Text('English'),
              trailing: UserSession.languagePref == 'en' ? const Icon(Icons.check, color: AppTheme.accentOrange) : null,
              onTap: () => Navigator.pop(context, 'en'),
            ),
            ListTile(
              title: const Text('हिन्दी'),
              trailing: UserSession.languagePref == 'hi' ? const Icon(Icons.check, color: AppTheme.accentOrange) : null,
              onTap: () => Navigator.pop(context, 'hi'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (chosen == null || chosen == UserSession.languagePref) return;

    setState(() => _updatingLanguage = true);
    try {
      await ApiService.updateLanguage(userId: UserSession.userId!, languagePref: chosen);
      await UserSession.setLanguage(chosen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update language: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingLanguage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBrown, AppTheme.primaryBrownDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UserSession.name ?? 'Guest',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        UserSession.phoneNumber ?? '',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                      ),
                      if (UserSession.isPremium) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: AppTheme.primaryBrownDark),
                              SizedBox(width: 4),
                              Text('Premium Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryBrownDark)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  trailing: _updatingLanguage
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(UserSession.languagePref == 'hi' ? 'हिन्दी' : 'English'),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                  onTap: _updatingLanguage ? null : _changeLanguage,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: const Text('Moon sign (Rashi)'),
                  trailing: UserSession.moonSignRashi != null
                      ? Text(UserSession.moonSignRashi!)
                      : TextButton(
                          onPressed: _openBirthDetails,
                          child: const Text('Generate kundli'),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Subscription'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(UserSession.isPremium ? UserSession.planType.toUpperCase() : 'Free'),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text('Family Profiles'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.warning),
              title: const Text('Log out', style: TextStyle(color: AppTheme.warning)),
              onTap: () async {
                await UserSession.clear();
                if (!context.mounted) return;
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
