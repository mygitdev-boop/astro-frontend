import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';

class YogasDoshasScreen extends StatefulWidget {
  const YogasDoshasScreen({super.key});

  @override
  State<YogasDoshasScreen> createState() => _YogasDoshasScreenState();
}

class _YogasDoshasScreenState extends State<YogasDoshasScreen> {
  List<dynamic> _yogas = [];
  List<dynamic> _doshas = [];
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
      final result = await ApiService.getYogasDoshas(UserSession.userId!);
      setState(() {
        _yogas = result['yogas'] ?? [];
        _doshas = result['doshas'] ?? [];
        _explanation = result['explanation'];
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
      appBar: AppBar(title: const Text('Yogas & Doshas')),
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
    final yogaCount = _yogas.where((y) => y['present'] == true).length;
    final doshaCount = _doshas.where((d) => d['present'] == true).length;

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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryStat(icon: Icons.auto_awesome, count: yogaCount, label: 'Yogas Found'),
              Container(width: 1, height: 40, color: Colors.white24),
              _SummaryStat(icon: Icons.warning_amber_rounded, count: doshaCount, label: 'Doshas Found'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_explanation != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AiMarkdownText(data: _explanation!),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('Yogas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._yogas.map((y) => _YogaDoshaTile(
              name: y['name'],
              present: y['present'],
              note: y['note'],
              positiveColor: true,
            )),
        const SizedBox(height: 20),
        Text('Doshas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._doshas.map((d) => _YogaDoshaTile(
              name: d['name'],
              present: d['present'],
              note: d['note'],
              positiveColor: false,
            )),
        const SizedBox(height: 16),
        Text(
          'These are traditional classical combinations based on planetary positions -- meant as guidance, not certainty.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  const _SummaryStat({required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ],
    );
  }
}

class _YogaDoshaTile extends StatelessWidget {
  final String name;
  final bool present;
  final String? note;
  final bool positiveColor; // yogas are framed positively, doshas cautiously

  const _YogaDoshaTile({
    required this.name,
    required this.present,
    required this.note,
    required this.positiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = positiveColor ? AppTheme.success : AppTheme.warning;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: present ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF0EEF5),
                  child: Icon(
                    present ? Icons.check_circle : Icons.remove_circle_outline,
                    size: 15,
                    color: present ? activeColor : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: TextStyle(fontWeight: FontWeight.w500, color: present ? AppTheme.textPrimary : AppTheme.textSecondary)),
                ),
                Text(
                  present ? 'Present' : 'Not present',
                  style: TextStyle(fontSize: 12, color: present ? activeColor : AppTheme.textSecondary),
                ),
              ],
            ),
            if (present && note != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(note!, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
