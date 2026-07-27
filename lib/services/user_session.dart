/// Holds the current user's identity for the duration of the app session.
///
/// NOTE: this is intentionally simple (in-memory only) to get the app
/// working end-to-end first. Before shipping, swap this for persistent
/// storage (e.g. the `shared_preferences` package) so the user doesn't
/// have to re-enter their phone number every time they reopen the app.
class UserSession {
  static int? userId;
  static String? name;
  static String? phoneNumber;
  static String languagePref = 'en';
  static String? moonSignRashi; // set after birth details are submitted
  static String planType = 'free'; // "free" / "monthly" / "yearly"

  static bool get isLoggedIn => userId != null;
  static bool get hasKundli => moonSignRashi != null;
  static bool get isPremium => planType != 'free';

  static void setUser({
    required int id,
    String? userName,
    required String phone,
    required String language,
  }) {
    userId = id;
    name = userName;
    phoneNumber = phone;
    languagePref = language;
  }

  static void clear() {
    userId = null;
    name = null;
    phoneNumber = null;
    languagePref = 'en';
    moonSignRashi = null;
    planType = 'free';
  }
}
