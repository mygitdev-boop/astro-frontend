import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';

/// Reports grid -- Career/Marriage/Finance/Health/Education/Business.
/// Each card generates a detailed report via the existing /consultation
/// endpoint (which is gated server-side to Monthly/Yearly plans only).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _reportTypes = [
    {'label': 'Career', 'icon': Icons.work_outline, 'concern': 'career prospects and growth'},
    {'label': 'Marriage', 'icon': Icons.favorite_outline, 'concern': 'marriage and relationships'},
    {'label': 'Finance', 'icon': Icons.currency_rupee, 'concern': 'wealth and financial growth'},
    {'label': 'Health', 'icon': Icons.health_and_safety_outlined, 'concern': 'health and wellbeing'},
    {'label': 'Education', 'icon': Icons.school_outlined, 'concern': 'education and learning'},
    {'label': 'Business', 'icon': Icons.storefront_outlined, 'concern': 'business and entrepreneurship'},
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
          childAspectRatio: 1.1,
        ),
        itemCount: _reportTypes.length,
        itemBuilder: (context, i) {
          final report = _reportTypes[i];
          return _ReportCard(
            label: report['label'] as String,
            icon: report['icon'] as IconData,
            concern: report['concern'] as String,
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String concern;
  const _ReportCard({required this.label, required this.icon, required this.concern});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(label: label, concern: concern)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.accentOrange),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
  final String concern;
  const ReportDetailScreen({super.key, required this.label, required this.concern});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String? _report;
  bool _loading = true;
  bool _needsUpgrade = false;
  String? _error;

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
                            child: Text(_report ?? '', style: Theme.of(context).textTheme.bodyLarge),
                          ),
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
