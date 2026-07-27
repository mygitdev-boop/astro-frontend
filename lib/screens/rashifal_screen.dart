import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'birth_details_screen.dart';

class RashifalScreen extends StatefulWidget {
  const RashifalScreen({super.key});

  @override
  State<RashifalScreen> createState() => _RashifalScreenState();
}

class _RashifalScreenState extends State<RashifalScreen> {
  static const _periods = ['daily', 'weekly', 'monthly', 'yearly'];
  static const _periodLabels = ['Today', 'Week', 'Month', 'Year'];

  int _selectedPeriod = 0;
  String? _content;
  bool _loading = true;
  String? _error;
  bool _needsKundli = false;

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
      _needsKundli = false;
    });
    try {
      final result = await ApiService.getRashifal(
        rashi,
        _periods[_selectedPeriod],
        language: UserSession.languagePref,
      );
      setState(() => _content = result['content']);
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
      appBar: AppBar(title: Text('Rashifal${UserSession.moonSignRashi != null ? ' · ${UserSession.moonSignRashi}' : ''}')),
      body: _needsKundli ? _buildNeedsKundli() : _buildTabsAndContent(),
    );
  }

  Widget _buildNeedsKundli() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.auto_awesome_outlined, size: 56, color: AppTheme.primaryIndigo),
        const SizedBox(height: 20),
        Text(
          'Generate your kundli to see your rashifal',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Your rashifal is based on your Moon sign, which comes from your birth chart.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: _openBirthDetails, child: const Text('Generate my kundli')),
      ],
    );
  }

  Widget _buildTabsAndContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(_periods.length, (i) {
              final selected = i == _selectedPeriod;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_periodLabels[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedPeriod = i);
                    _load();
                  },
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _content ?? 'No content available yet.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
