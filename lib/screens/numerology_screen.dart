import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';
import 'subscription_screen.dart';

class NumerologyScreen extends StatefulWidget {
  const NumerologyScreen({super.key});

  @override
  State<NumerologyScreen> createState() => _NumerologyScreenState();
}

class _NumerologyScreenState extends State<NumerologyScreen> {
  Map<String, dynamic>? _numbers;
  String? _explanation;
  bool _premium = false;
  bool _loading = true;
  String? _error;

  static const _numberInfo = [
    {'key': 'life_path_number', 'label': 'Life Path', 'icon': Icons.route_outlined, 'color': Color(0xFF4A7FE8)},
    {'key': 'destiny_number', 'label': 'Destiny', 'icon': Icons.stars_outlined, 'color': Color(0xFFE85D75)},
    {'key': 'soul_number', 'label': 'Soul', 'icon': Icons.favorite_outline, 'color': Color(0xFF9B6FE8)},
    {'key': 'name_number', 'label': 'Name', 'icon': Icons.badge_outlined, 'color': Color(0xFF2E9E5B)},
    {'key': 'lucky_number', 'label': 'Lucky', 'icon': Icons.tag, 'color': Color(0xFFF5A623)},
  ];

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
      final result = await ApiService.getNumerology(UserSession.userId!);
      setState(() {
        _numbers = result['numbers'];
        _explanation = result['explanation'];
        _premium = result['premium'] == true;
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
      appBar: AppBar(title: const Text('Numerology')),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('Your Numbers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 14,
                children: _numberInfo.map((info) {
                  final value = _numbers?[info['key']];
                  return SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Text(info['label'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_explanation != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AiMarkdownText(data: _explanation!),
            ),
          ),
        if (!_premium) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Unlock full breakdown of all 5 numbers'),
          ),
        ],
      ],
    );
  }
}
