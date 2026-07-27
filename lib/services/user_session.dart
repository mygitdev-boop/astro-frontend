import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the current user's identity for the duration of the app session,
/// persisted to disk via shared_preferences so the user doesn't have to
/// re-register every time they reopen the app.
///
/// Call `UserSession.load()` once at app startup (before deciding which
/// screen to show) to restore a previous session, if one exists.
class UserSession {
  static int? userId;
  static String? name;
  static String? phoneNumber;
  static String languagePref = 'en';
  static String? moonSignRashi; // set after birth details are submitted
  static String planType = 'free'; // "free" / "monthly" / "yearly"

  // Fires whenever the kundli is generated/updated. Screens that depend on
  // moonSignRashi (Rashifal, Home, Kundli) listen to this and refresh --
  // needed because the app uses an IndexedStack for its bottom tabs, which
  // keeps every tab alive in memory. Without this, generating your kundli
  // on one tab wouldn't be noticed by another tab already sitting in memory.
  static final ValueNotifier<int> kundliUpdateSignal = ValueNotifier(0);

  static bool get isLoggedIn => userId != null;
  static bool get hasKundli => moonSignRashi != null;
  static bool get isPremium => planType != 'free';

  static const _keyUserId = 'user_id';
  static const _keyName = 'user_name';
  static const _keyPhone = 'user_phone';
  static const _keyLanguage = 'user_language';
  static const _keyMoonSign = 'user_moon_sign';

  /// Restores a previous session from disk, if one exists. Call this once
  /// at app startup before deciding whether to show onboarding or the
  /// main app -- see main.dart.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt(_keyUserId);
    name = prefs.getString(_keyName);
    phoneNumber = prefs.getString(_keyPhone);
    languagePref = prefs.getString(_keyLanguage) ?? 'en';
    moonSignRashi = prefs.getString(_keyMoonSign);
  }

  static Future<void> setUser({
    required int id,
    String? userName,
    required String phone,
    required String language,
  }) async {
    userId = id;
    name = userName;
    phoneNumber = phone;
    languagePref = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    if (userName != null) await prefs.setString(_keyName, userName);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyLanguage, language);
  }

  /// Called once a kundli is generated -- persists the moon sign so
  /// Rashifal/Kundli screens know it's available even after an app restart,
  /// and notifies any listening screens (see kundliUpdateSignal above).
  static Future<void> setMoonSign(String rashi) async {
    moonSignRashi = rashi;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMoonSign, rashi);
    kundliUpdateSignal.value++;
  }

  static Future<void> setLanguage(String language) async {
    languagePref = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  static Future<void> clear() async {
    userId = null;
    name = null;
    phoneNumber = null;
    languagePref = 'en';
    moonSignRashi = null;
    planType = 'free';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyMoonSign);
  }
}
