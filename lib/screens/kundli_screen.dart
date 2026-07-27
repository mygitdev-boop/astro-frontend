import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  Map<String, dynamic>? _chart;
  String? _explanation;
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
      final results = await Future.wait([
        ApiService.getKundli(UserSession.userId!),
        ApiService.getKundliExplanation(UserSession.userId!),
      ]);
      setState(() {
        _chart = results[0]['chart_json'];
        _explanation = results[1]['explanation'];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your kundli')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                ))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final asc = _chart?['ascendant']?['sign'];
    final moon = _chart?['moon_sign']?['sign'];
    final nakshatra = _chart?['moon_sign']?['nakshatra'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            if (asc != null) _ChartChip(label: '$asc ascendant'),
            if (moon != null) _ChartChip(label: '$moon moon'),
            if (nakshatra != null) _ChartChip(label: nakshatra),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _explanation ?? 'No explanation available yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartChip extends StatelessWidget {
  final String label;
  const _ChartChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentSaffronLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
