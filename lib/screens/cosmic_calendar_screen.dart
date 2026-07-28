import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

/// "Cosmic Calendar" -- traditional monthly guidance on favorable windows
/// for Marriage/Interview/Travel/Investment/Business, based on the user's
/// Moon sign.
class CosmicCalendarScreen extends StatefulWidget {
  const CosmicCalendarScreen({super.key});

  @override
  State<CosmicCalendarScreen> createState() => _CosmicCalendarScreenState();
}

class _CosmicCalendarScreenState extends State<CosmicCalendarScreen> {
  Map<String, dynamic>? _calendar;
  bool _loading = true;
  String? _error;
  bool _needsKundli = false;

  static const _categories = [
    {'key': 'marriage', 'label': 'Marriage', 'icon': Icons.favorite_outline},
    {'key': 'interview', 'label': 'Interview', 'icon': Icons.work_outline},
    {'key': 'travel', 'label': 'Travel', 'icon': Icons.flight_outlined},
    {'key': 'investment', 'label': 'Investment', 'icon': Icons.trending_up},
    {'key': 'business', 'label': 'Business', 'icon': Icons.storefront_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rashi = UserSession.moonSignRashi;
    if (rashi == null) {
      setState(() {
        _loading = false;
        _needsKundli = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getCosmicCalendar(rashi, language: UserSession.languagePref);
      setState(() => _calendar = result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = _monthName(now.month);

    return Scaffold(
      appBar: AppBar(title: Text('Cosmic Calendar · $monthLabel')),
      body: _needsKundli
          ? _buildNeedsKundli()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                      ),
                    )
                  : _buildContent(),
    );
  }

  Widget _buildNeedsKundli() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.calendar_month_outlined, size: 56, color: AppTheme.primaryBrown),
        const SizedBox(height: 20),
        Text(
          'Generate your kundli to see your Cosmic Calendar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          "This is based on your Moon sign's current transits.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
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
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.calendar_month, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This Month\'s Guidance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Traditional guidance on favorable windows -- not a guaranteed prediction.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._categories.map((cat) {
          final value = _calendar?[cat['key']];
          if (value == null) return const SizedBox.shrink();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentOrangeLight,
                    child: Icon(cat['icon'] as IconData, size: 17, color: AppTheme.accentOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(value, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
