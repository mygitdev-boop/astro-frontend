import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

class DivisionalChartsScreen extends StatefulWidget {
  const DivisionalChartsScreen({super.key});

  @override
  State<DivisionalChartsScreen> createState() => _DivisionalChartsScreenState();
}

class _DivisionalChartsScreenState extends State<DivisionalChartsScreen> {
  Map<String, dynamic>? _d9;
  Map<String, dynamic>? _d10;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getDivisionalCharts(UserSession.userId!);
      setState(() {
        _d9 = result['D9_navamsa'];
        _d10 = result['D10_dasamsa'];
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Divisional charts')),
      body: _loading
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

  static const _planetIcons = {
    'Sun': (Icons.wb_sunny, Color(0xFFE8720C)),
    'Moon': (Icons.nightlight_round, Color(0xFF4A7FE8)),
    'Mars': (Icons.local_fire_department, Color(0xFFD9531E)),
    'Mercury': (Icons.eco, Color(0xFF2E9E5B)),
    'Jupiter': (Icons.auto_awesome, Color(0xFFF5A623)),
    'Venus': (Icons.favorite, Color(0xFFE85D9C)),
    'Saturn': (Icons.hourglass_bottom, Color(0xFF5C6B7A)),
    'Rahu': (Icons.blur_circular, Color(0xFF7E57A8)),
    'Ketu': (Icons.blur_on, Color(0xFF8A7460)),
    'Ascendant': (Icons.arrow_upward, Color(0xFFE8720C)),
  };

  Widget _buildContent() {
    final planets = _d9!.keys.toList();
    const order = ['Ascendant', 'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
    final sortedPlanets = order.where((p) => planets.contains(p)).toList();

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
                child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Divisional Charts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'D9 (Navamsa): marriage & inner strength. D10 (Dasamsa): career & public life.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Planet', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(flex: 3, child: Text('D9 Navamsa', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text('D10 Dasamsa', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...sortedPlanets.map((planet) {
                final iconData = _planetIcons[planet];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: (iconData?.$2 ?? AppTheme.accentOrange).withValues(alpha: 0.12),
                              child: Icon(iconData?.$1 ?? Icons.circle, size: 12, color: iconData?.$2 ?? AppTheme.accentOrange),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(planet, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                          ],
                        ),
                      ),
                      Expanded(flex: 3, child: Text(_d9![planet] ?? '--', textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text(_d10![planet] ?? '--', textAlign: TextAlign.center)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
