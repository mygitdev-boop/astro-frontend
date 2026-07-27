import 'package:flutter/material.dart';
import 'config.dart';
import 'theme/app_theme.dart';
import 'services/user_session.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.load(); // restore a previous session, if one exists
  await AdsService.initialize();
  AdsService.loadInterstitial();
  AdsService.loadRewarded();
  await NotificationService.initialize();
  runApp(const AstroBhavishyaApp());
}

class AstroBhavishyaApp extends StatelessWidget {
  const AstroBhavishyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // UserSession.load() above (called before runApp) restores a previous
      // session from disk, so returning users go straight to the main app
      // instead of seeing onboarding again.
      home: UserSession.isLoggedIn ? const MainNavScreen() : const OnboardingScreen(),
    );
  }
}
