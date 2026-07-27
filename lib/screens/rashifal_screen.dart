import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

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
        _error = 'Complete your birth details first to see your rashifal.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rashifal · ${UserSession.moonSignRashi ?? ''}')),
      body: Column(
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
      ),
    );
  }
}
