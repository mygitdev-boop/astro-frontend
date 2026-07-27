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

  Widget _buildContent() {
    final planets = _d9!.keys.toList();
    const order = ['Ascendant', 'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
    final sortedPlanets = order.where((p) => planets.contains(p)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'D9 (Navamsa) relates to marriage and inner strength. D10 (Dasamsa) relates to career and public life.',
          style: Theme.of(context).textTheme.bodyMedium,
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
              ...sortedPlanets.map((planet) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(planet, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Expanded(flex: 3, child: Text(_d9![planet] ?? '--', textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text(_d10![planet] ?? '--', textAlign: TextAlign.center)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
