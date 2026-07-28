import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';
import '../widgets/ai_markdown_text.dart';

/// Reports grid -- Career/Marriage/Money/Business/Children/Health/Travel.
/// Each card generates a detailed report via the existing /consultation
/// endpoint (which is gated server-side to Monthly/Yearly plans only),
/// and can also be downloaded as a branded PDF (bilingual, Hindi/English).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _reportTypes = [
    {'label': 'Career', 'subtitle': 'Know your career potential', 'category': 'career', 'icon': Icons.work_outline, 'color': Color(0xFF4A7FE8), 'concern': 'career prospects and growth'},
    {'label': 'Marriage', 'subtitle': 'Analyze marriage prospects', 'category': 'marriage', 'icon': Icons.favorite_outline, 'color': Color(0xFFE85D75), 'concern': 'marriage and relationships'},
    {'label': 'Money', 'subtitle': 'Financial growth and stability', 'category': 'money', 'icon': Icons.currency_rupee, 'color': Color(0xFF2E9E5B), 'concern': 'wealth and financial growth'},
    {'label': 'Business', 'subtitle': 'Business growth and profits', 'category': 'business', 'icon': Icons.storefront_outlined, 'color': Color(0xFFF5A623), 'concern': 'business and entrepreneurship'},
    {'label': 'Children', 'subtitle': 'Child future and personality', 'category': 'children', 'icon': Icons.child_friendly_outlined, 'color': Color(0xFF9B6FE8), 'concern': 'children and family planning'},
    {'label': 'Health', 'subtitle': 'Health insights and remedies', 'category': 'health', 'icon': Icons.health_and_safety_outlined, 'color': Color(0xFF3EBFB0), 'concern': 'health and wellbeing'},
    {'label': 'Travel', 'subtitle': 'Travel timing and prospects', 'category': 'travel', 'icon': Icons.flight_outlined, 'color': Color(0xFFE8720C), 'concern': 'travel and relocation prospects'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: _reportTypes.length,
        itemBuilder: (context, i) {
          final report = _reportTypes[i];
          return _ReportCard(
            label: report['label'] as String,
            subtitle: report['subtitle'] as String,
            category: report['category'] as String,
            icon: report['icon'] as IconData,
            color: report['color'] as Color,
            concern: report['concern'] as String,
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final String concern;
  const _ReportCard({
    required this.label,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.concern,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(label: label, category: category, concern: concern)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the generated report, or a paywall prompt if the user isn't
/// on an active Monthly/Yearly plan (backend returns 403 for that case).
class ReportDetailScreen extends StatefulWidget {
  final String label;
  final String category;
  final String concern;
  const ReportDetailScreen({super.key, required this.label, required this.category, required this.concern});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String? _report;
  bool _loading = true;
  bool _needsUpgrade = false;
  String? _error;

  Future<void> _downloadPdf() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/users/${UserSession.userId}/report-pdf?category=${widget.category}&language=${UserSession.languagePref}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF. Please try again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsUpgrade = false;
    });
    try {
      final result = await ApiService.detailedConsultation(
        userId: UserSession.userId!,
        primaryConcern: widget.concern,
        category: widget.category,
      );
      setState(() => _report = result['answer']);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        setState(() => _needsUpgrade = true);
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.label} report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _needsUpgrade
              ? _buildUpgradePrompt()
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
                            child: AiMarkdownText(data: _report ?? ''),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _downloadPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('Download as PDF'),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildUpgradePrompt() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.lock_outline, size: 48, color: AppTheme.accentOrange),
        const SizedBox(height: 20),
        Text(
          '${widget.label} report is a premium feature',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Upgrade to Monthly or Yearly to unlock detailed reports across career, marriage, finance, and more.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          ),
          child: const Text('View plans'),
        ),
      ],
    );
  }
}
