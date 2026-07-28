import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'birth_details_screen.dart';
import '../widgets/ai_markdown_text.dart';

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
  String? _luckyColor;
  int? _luckyNumber;
  String? _remedy;
  bool _loading = true;
  String? _error;
  bool _needsKundli = false;

  @override
  void initState() {
    super.initState();
    _load();
    UserSession.kundliUpdateSignal.addListener(_onKundliUpdated);
  }

  @override
  void dispose() {
    UserSession.kundliUpdateSignal.removeListener(_onKundliUpdated);
    super.dispose();
  }

  void _onKundliUpdated() {
    if (mounted) _load(); // kundli was generated/updated elsewhere -- refresh
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
      setState(() {
        _content = result['content'];
        _luckyColor = result['lucky_color'];
        _luckyNumber = result['lucky_number'];
        _remedy = result['remedy'];
      });
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
        const Icon(Icons.auto_awesome_outlined, size: 56, color: AppTheme.primaryBrown),
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
                            child: AiMarkdownText(data: _content ?? 'No content available yet.'),
                          ),
                        ),
                        if (_luckyColor != null || _luckyNumber != null || _remedy != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Today's lucky & remedy", style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      if (_luckyColor != null)
                                        _LuckyChip(icon: Icons.circle, label: 'Color', value: _luckyColor!),
                                      if (_luckyNumber != null)
                                        _LuckyChip(icon: Icons.tag, label: 'Number', value: '$_luckyNumber'),
                                    ],
                                  ),
                                  if (_remedy != null) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.spa_outlined, size: 16, color: AppTheme.accentOrange),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_remedy!, style: Theme.of(context).textTheme.bodyMedium)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

class _LuckyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LuckyChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.accentOrange),
        const SizedBox(width: 6),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
