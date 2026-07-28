import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Thrown when the backend returns a non-2xx response, carrying the
/// server's error detail message so the UI can show something meaningful
/// instead of a generic "something went wrong".
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Central place for every call to the Astro BhavishyaAI backend.
/// Mirrors the endpoints built in main.py -- keep this in sync if the
/// backend API changes.
class ApiService {
  static final Uri _base = Uri.parse(AppConfig.apiBaseUrl);

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Something went wrong. Please try again.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      // response wasn't JSON -- fall back to the generic message above
    }
    throw ApiException(response.statusCode, message);
  }

  // ---- Users ----

  static Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    final uri = _base.replace(path: '/users/check-phone', queryParameters: {'phone_number': phoneNumber});
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createUser({
    required String phoneNumber,
    String? name,
    String? gender,
    String languagePref = 'en',
  }) async {
    final res = await http.post(
      _base.replace(path: '/users'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'phone_number': phoneNumber,
        'name': name,
        'gender': gender,
        'language_pref': languagePref,
      }),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateLanguage({
    required int userId,
    required String languagePref,
  }) async {
    final res = await http.patch(
      _base.replace(path: '/users/$userId/language'),
      headers: _jsonHeaders,
      body: jsonEncode({'language_pref': languagePref}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final res = await http.get(_base.replace(path: '/users/$userId'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> registerWithVerifiedPhone({
    required String idToken,
    String? name,
    String? gender,
    String languagePref = 'en',
  }) async {
    final res = await http.post(
      _base.replace(path: '/auth/register-with-phone'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'id_token': idToken,
        'name': name,
        'gender': gender,
        'language_pref': languagePref,
      }),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Birth details / Kundli ----

  static Future<Map<String, dynamic>> submitBirthDetails({
    required int userId,
    required String date, // "YYYY-MM-DD"
    required String time, // "HH:MM"
    required double tzOffsetHours,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/birth-details'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'date': date,
        'time': time,
        'tz_offset_hours': tzOffsetHours,
        'latitude': latitude,
        'longitude': longitude,
        'place_name': placeName,
      }),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKundli(int userId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/kundli'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKundliExplanation(
    int userId, {
    String? language,
  }) async {
    final uri = _base.replace(
      path: '/users/$userId/kundli-explanation',
      queryParameters: language != null ? {'language': language} : null,
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTimingRemediesPredictions(
    int userId, {
    String? language,
  }) async {
    final uri = _base.replace(
      path: '/users/$userId/timing-remedies-predictions',
      queryParameters: language != null ? {'language': language} : null,
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDivisionalCharts(int userId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/divisional-charts'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getBirthStory(int userId, {String? language}) async {
    final uri = _base.replace(
      path: '/users/$userId/birth-story',
      queryParameters: language != null ? {'language': language} : null,
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getYogasDoshas(
    int userId, {
    String? language,
  }) async {
    final uri = _base.replace(
      path: '/users/$userId/yogas-doshas',
      queryParameters: language != null ? {'language': language} : null,
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Home feed ----

  static Future<Map<String, dynamic>> getHomeFeed(
    int userId, {
    String? language,
  }) async {
    final uri = _base.replace(
      path: '/users/$userId/home-feed',
      queryParameters: language != null ? {'language': language} : null,
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Rashifal ----

  static Future<Map<String, dynamic>> getRashifal(
    String rashi,
    String periodType, {
    String language = 'en',
  }) async {
    final uri = _base.replace(
      path: '/rashifal/$rashi/$periodType',
      queryParameters: {'language': language},
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Chat ----

  static Future<Map<String, dynamic>> getQuickQuestions({String language = 'en'}) async {
    final uri = _base.replace(path: '/quick-questions', queryParameters: {'language': language});
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> chatWithAstrologer({
    required int userId,
    required String question,
    String? category,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/chat'),
      headers: _jsonHeaders,
      body: jsonEncode({'question': question, 'category': category}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getChatHistory(int userId, {int limit = 50}) async {
    final uri = _base.replace(
      path: '/users/$userId/chat-history',
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> detailedConsultation({
    required int userId,
    required String primaryConcern,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/consultation'),
      headers: _jsonHeaders,
      body: jsonEncode({'primary_concern': primaryConcern}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Panchang ----

  static Future<Map<String, dynamic>> getTodaysPanchang({
    double? latitude,
    double? longitude,
    double? tzOffsetHours,
  }) async {
    final params = <String, String>{};
    if (latitude != null) params['latitude'] = '$latitude';
    if (longitude != null) params['longitude'] = '$longitude';
    if (tzOffsetHours != null) params['tz_offset_hours'] = '$tzOffsetHours';
    final uri = _base.replace(path: '/panchang/today', queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTodaysDevotional() async {
    final res = await http.get(_base.replace(path: '/devotional/today'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addFamilyMember({
    required int userId,
    required String name,
    required String relation,
    String? gender,
    required String date,
    required String time,
    required double tzOffsetHours,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/family'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'relation': relation,
        'gender': gender,
        'date': date,
        'time': time,
        'tz_offset_hours': tzOffsetHours,
        'latitude': latitude,
        'longitude': longitude,
        'place_name': placeName,
      }),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getFamilyMembers(int userId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/family'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getFamilyMemberDetail(int userId, int memberId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/family/$memberId'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getFamilyMemberExplanation(int userId, int memberId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/family/$memberId/kundli-explanation'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getChildAstrologyReport(int userId, int memberId) async {
    final res = await http.get(_base.replace(path: '/users/$userId/family/$memberId/child-report'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<void> deleteFamilyMember(int userId, int memberId) async {
    final res = await http.delete(_base.replace(path: '/users/$userId/family/$memberId'));
    _handleResponse(res);
  }

  // ---- Compatibility ----

  static Future<Map<String, dynamic>> checkCompatibility({
    required Map<String, dynamic> personA,
    required Map<String, dynamic> personB,
    String language = 'en',
  }) async {
    final res = await http.post(
      _base.replace(path: '/compatibility/check'),
      headers: _jsonHeaders,
      body: jsonEncode({'person_a': personA, 'person_b': personB, 'language': language}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getCosmicCalendar(String rashi, {String language = 'en'}) async {
    final uri = _base.replace(path: '/cosmic-calendar/$rashi', queryParameters: {'language': language});
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Festivals ----

  static Future<Map<String, dynamic>> getUpcomingFestivals({int limit = 5}) async {
    final uri = _base.replace(
      path: '/festivals/upcoming',
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(uri);
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> rewardBonusQuestion(int userId) async {
    final res = await http.post(_base.replace(path: '/users/$userId/reward-bonus-question'));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> registerFcmToken({
    required int userId,
    required String fcmToken,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/register-fcm-token'),
      headers: _jsonHeaders,
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  // ---- Payments ----

  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String planType, // "monthly" or "yearly"
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/create-order'),
      headers: _jsonHeaders,
      body: jsonEncode({'plan_type': planType}),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int userId,
    required String orderId,
    required String paymentId,
    required String signature,
    required String planType,
  }) async {
    final res = await http.post(
      _base.replace(path: '/users/$userId/verify-payment'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
        'plan_type': planType,
      }),
    );
    return _handleResponse(res) as Map<String, dynamic>;
  }
}
