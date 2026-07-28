import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';

/// "AI Birth Story" -- a narrative, storytelling explanation of the sky
/// at the moment the user was born, instead of a dry technical breakdown.
class BirthStoryScreen extends StatefulWidget {
  const BirthStoryScreen({super.key});

  @override
  State<BirthStoryScreen> createState() => _BirthStoryScreenState();
}

class _BirthStoryScreenState extends State<BirthStoryScreen> {
  String? _story;
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
      final result = await ApiService.getBirthStory(UserSession.userId!);
      setState(() => _story = result['story']);
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
      appBar: AppBar(title: const Text('Your birth story')),
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Icon(Icons.auto_stories, size: 40, color: AppTheme.accentOrange),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: AiMarkdownText(data: _story ?? 'No story available yet.'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
