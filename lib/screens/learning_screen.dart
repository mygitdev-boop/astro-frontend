import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  Map<String, dynamic>? _lessonData;
  bool _loading = true;
  bool _completing = false;
  String? _error;

  static const _badgeIcons = {
    'Curious Beginner': Icons.emoji_events_outlined,
    'Dedicated Learner': Icons.military_tech_outlined,
    'Astrology Scholar': Icons.workspace_premium_outlined,
  };

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
      final result = await ApiService.getTodaysLesson(UserSession.userId!);
      setState(() => _lessonData = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markComplete() async {
    final lessonId = _lessonData?['lesson']?['id'];
    if (lessonId == null) return;
    setState(() => _completing = true);
    try {
      await ApiService.completeLesson(UserSession.userId!, lessonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson complete! Come back tomorrow for the next one.')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astrology Learning')),
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
    final lesson = _lessonData?['lesson'];
    final completedToday = _lessonData?['completed_today'] == true;
    final totalCompleted = _lessonData?['total_completed'] ?? 0;
    final badges = (_lessonData?['badges'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$totalCompleted', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.primaryBrown)),
                    Text('lessons completed', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text("Today's lesson", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 18, color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lesson?['question'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(lesson?['answer'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (completedToday || _completing) ? null : _markComplete,
                    child: _completing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(completedToday ? 'Completed today ✓' : 'Mark as complete'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Your badges', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          Text('Complete 5 lessons to earn your first badge.', style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.map<Widget>((badge) {
              return Chip(
                avatar: Icon(_badgeIcons[badge] ?? Icons.star, size: 18, color: AppTheme.accentOrange),
                label: Text(badge),
              );
            }).toList(),
          ),
      ],
    );
  }
}
