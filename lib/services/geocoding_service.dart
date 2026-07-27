import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resolves a typed city name into coordinates, using Open-Meteo's free
/// geocoding API (no API key required, CORS-enabled).
///
/// NOTE on timezone: we don't attempt to resolve historical UTC offsets
/// per city here (that requires a full IANA timezone database and correct
/// handling of DST/historical zone changes, which is a bigger undertaking).
/// Since this app targets the Indian market, we default every user to
/// IST (+5.5). If you add international users later, swap this for the
/// `timezone` package with proper tz-database lookups keyed off each
/// result's `timezone` field (already returned by the API below).
class CityResult {
  final String name;
  final String? admin1; // state/region
  final String country;
  final double latitude;
  final double longitude;
  final String timezone; // IANA name, e.g. "Asia/Kolkata" -- not yet used, see note above

  CityResult({
    required this.name,
    this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  String get displayLabel {
    final parts = [name, if (admin1 != null) admin1, country];
    return parts.join(', ');
  }

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name'] ?? '',
      admin1: json['admin1'],
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }
}

class GeocodingService {
  static const String _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  static Future<List<CityResult>> searchCity(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'name': query.trim(),
      'count': '8',
      'language': 'en',
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final results = data['results'] as List<dynamic>?;
      if (results == null) return [];
      return results.map((r) => CityResult.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }
}
