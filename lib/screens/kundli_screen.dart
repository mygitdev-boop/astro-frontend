import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'birth_details_screen.dart';
import 'reports_screen.dart';
import 'compatibility_screen.dart';

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
  bool _needsKundli = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsKundli = false;
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
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        setState(() => _needsKundli = true);
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBirthDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BirthDetailsScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your kundli')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _needsKundli
              ? _buildNeedsKundli()
              : _error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                    ))
                  : _buildContent(),
    );
  }

  Widget _buildNeedsKundli() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.auto_stories_outlined, size: 56, color: AppTheme.primaryBrown),
        const SizedBox(height: 20),
        Text(
          "You haven't generated your kundli yet",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Add your birth details to see your full chart and a step-by-step explanation.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: _openBirthDetails, child: const Text('Generate my kundli')),
      ],
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
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          ),
          icon: const Icon(Icons.description_outlined, size: 18),
          label: const Text('View detailed reports'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompatibilityScreen()),
          ),
          icon: const Icon(Icons.favorite_outline, size: 18),
          label: const Text('Check compatibility'),
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
        color: AppTheme.accentOrangeLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
