import 'package:flutter/material.dart';
import 'config.dart';
import 'theme/app_theme.dart';
import 'services/user_session.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_nav_screen.dart';

void main() {
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
      // NOTE: UserSession is in-memory only right now (see user_session.dart),
      // so this always starts at onboarding on a fresh app launch. Once
      // persistent storage is added, check UserSession.isLoggedIn here and
      // route straight to MainNavScreen for returning users.
      home: UserSession.isLoggedIn ? const MainNavScreen() : const OnboardingScreen(),
    );
  }
}
