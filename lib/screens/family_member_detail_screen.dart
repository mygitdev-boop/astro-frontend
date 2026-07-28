import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';

class FamilyMemberDetailScreen extends StatefulWidget {
  final int memberId;
  final String name;
  final String? relation;
  const FamilyMemberDetailScreen({super.key, required this.memberId, required this.name, this.relation});

  @override
  State<FamilyMemberDetailScreen> createState() => _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen> {
  Map<String, dynamic>? _chart;
  String? _explanation;
  String? _childReport;
  bool _loading = true;
  bool _loadingExplanation = false;
  bool _loadingChildReport = false;
  String? _error;

  bool get _isChild => widget.relation == 'son' || widget.relation == 'daughter';

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
      final result = await ApiService.getFamilyMemberDetail(UserSession.userId!, widget.memberId);
      setState(() => _chart = result['chart']);
      _loadExplanation();
      if (_isChild) _loadChildReport();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadExplanation() async {
    setState(() => _loadingExplanation = true);
    try {
      final result = await ApiService.getFamilyMemberExplanation(UserSession.userId!, widget.memberId);
      if (mounted) setState(() => _explanation = result['explanation']);
    } catch (_) {
      // Non-critical -- dashboard summary still shows without the explanation
    } finally {
      if (mounted) setState(() => _loadingExplanation = false);
    }
  }

  Future<void> _loadChildReport() async {
    setState(() => _loadingChildReport = true);
    try {
      final result = await ApiService.getChildAstrologyReport(UserSession.userId!, widget.memberId);
      if (mounted) setState(() => _childReport = result['report']);
    } catch (_) {
      // Non-critical -- rest of dashboard still shows
    } finally {
      if (mounted) setState(() => _loadingChildReport = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove family member?'),
        content: Text('This will remove ${widget.name}\'s profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteFamilyMember(UserSession.userId!, widget.memberId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
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
    final asc = _chart?['ascendant']?['sign'];
    final moon = _chart?['moon_sign']?['sign'];
    final nakshatra = _chart?['moon_sign']?['nakshatra'];
    final dasha = _chart?['dasha'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _ChartChip(label: 'Ascendant', value: asc ?? '--'),
                _ChartChip(label: 'Moon Sign', value: moon ?? '--'),
                _ChartChip(label: 'Nakshatra', value: nakshatra ?? '--'),
                if (dasha != null) _ChartChip(label: 'Mahadasha', value: dasha['current_mahadasha'] ?? '--'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loadingExplanation
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : AiMarkdownText(data: _explanation ?? 'No explanation available yet.'),
          ),
        ),
        if (_isChild) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.child_care, size: 18, color: AppTheme.accentOrange),
                      const SizedBox(width: 8),
                      Text('Child Astrology Report', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learning style, strengths, personality, and interests -- traditional interpretation, not a prediction.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _loadingChildReport
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      : AiMarkdownText(data: _childReport ?? 'No report available yet.'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartChip extends StatelessWidget {
  final String label;
  final String value;
  const _ChartChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
