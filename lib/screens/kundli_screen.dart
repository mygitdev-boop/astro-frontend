import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'birth_details_screen.dart';
import 'reports_screen.dart';
import 'compatibility_screen.dart';
import 'yogas_doshas_screen.dart';
import 'divisional_charts_screen.dart';
import 'remedies_screen.dart';
import 'birth_story_screen.dart';
import '../widgets/ai_markdown_text.dart';

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
    UserSession.kundliUpdateSignal.addListener(_onKundliUpdated);
  }

  @override
  void dispose() {
    UserSession.kundliUpdateSignal.removeListener(_onKundliUpdated);
    super.dispose();
  }

  void _onKundliUpdated() {
    if (mounted) _load();
  }

  Future<void> _downloadPdf() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/${UserSession.userId}/kundli-pdf');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF. Please try again.')),
      );
    }
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
  };

  Widget _buildContent() {
    final asc = _chart?['ascendant']?['sign'];
    final moon = _chart?['moon_sign']?['sign'];
    final nakshatra = _chart?['moon_sign']?['nakshatra'];
    final planets = (_chart?['planets'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Header: gradient card with the 3 core stats ---
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
              _HeaderStat(label: 'Ascendant', value: asc ?? '--'),
              _HeaderStat(label: 'Moon Sign', value: moon ?? '--'),
              _HeaderStat(label: 'Nakshatra', value: nakshatra ?? '--'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Planet Positions grid ---
        if (planets.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planet Positions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.2,
                    children: planets.entries.map((e) {
                      final info = e.value as Map<String, dynamic>;
                      final iconData = _planetIcons[e.key];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: (iconData?.$2 ?? AppTheme.accentOrange).withValues(alpha: 0.12),
                            child: Icon(iconData?.$1 ?? Icons.circle, size: 15, color: iconData?.$2 ?? AppTheme.accentOrange),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(
                                  '${info['sign'] ?? ''} · H${info['house'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // --- AI explanation ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AiMarkdownText(data: _explanation ?? 'No explanation available yet.'),
          ),
        ),
        const SizedBox(height: 16),

        // --- More / navigation menu ---
        Card(
          child: Column(
            children: [
              _MenuTile(icon: Icons.picture_as_pdf_outlined, label: 'Download as PDF', onTap: _downloadPdf),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.description_outlined,
                label: 'View detailed reports',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.favorite_outline,
                label: 'Check compatibility',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompatibilityScreen())),
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.auto_awesome_outlined,
                label: 'View yogas & doshas',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YogasDoshasScreen())),
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.grid_view_outlined,
                label: 'Divisional charts (D9/D10)',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DivisionalChartsScreen())),
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.spa_outlined,
                label: 'Remedies & timing',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemediesScreen())),
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.auto_stories_outlined,
                label: 'Your birth story',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthStoryScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.accentOrangeLight,
        child: Icon(icon, size: 17, color: AppTheme.accentOrange),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
