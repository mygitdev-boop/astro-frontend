import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';

/// "AI Remedy Generator" -- practical, traditional remedy suggestions
/// (meditation, charity, discipline, mantra) tied to the user's current
/// planetary period, rather than just "wear this gemstone."
class RemediesScreen extends StatefulWidget {
  const RemediesScreen({super.key});

  @override
  State<RemediesScreen> createState() => _RemediesScreenState();
}

class _RemediesScreenState extends State<RemediesScreen> {
  String? _report;
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
      final result = await ApiService.getTimingRemediesPredictions(UserSession.userId!);
      setState(() => _report = result['report']);
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
      appBar: AppBar(title: const Text('Remedies & Timing')),
      body: _loading
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
                        child: AiMarkdownText(data: _report ?? 'No content available yet.'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'These are traditional Vedic practices offered as guidance -- not guaranteed remedies. Consider them alongside your own judgment.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
    );
  }
}
