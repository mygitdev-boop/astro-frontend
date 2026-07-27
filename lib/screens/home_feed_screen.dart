import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  Map<String, dynamic>? _feed;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await ApiService.getHomeFeed(UserSession.userId!);
      setState(() => _feed = feed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astro BhavishyaAI')),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildFeed(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.warning)),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: _loadFeed, child: const Text('Retry'))),
      ],
    );
  }

  Widget _buildFeed() {
    final feed = _feed!;
    final ratings = feed['ratings'] as Map<String, dynamic>? ?? {};
    final lucky = feed['lucky'] as Map<String, dynamic>? ?? {};
    final dasha = feed['current_dasha'] as Map<String, dynamic>? ?? {};
    final feedItems = feed['feed'] as Map<String, dynamic>? ?? {};
    final quickQuestions = feed['quick_questions'] as Map<String, dynamic>? ?? {};
    final recommended = feed['recommended'] as List<dynamic>? ?? [];
    final continueChat = feed['continue_chat'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreetingCard(feed),
        const SizedBox(height: 16),
        _buildTodaysHighlights(ratings),
        const SizedBox(height: 16),
        _buildDashaCard(dasha),
        const SizedBox(height: 16),
        _buildLuckyCard(lucky),
        const SizedBox(height: 16),
        _buildQuickQuestions(quickQuestions),
        const SizedBox(height: 16),
        if (feedItems.isNotEmpty) _buildFeedItems(feedItems),
        const SizedBox(height: 16),
        if (recommended.isNotEmpty) _buildRecommended(recommended),
        if (continueChat != null) ...[
          const SizedBox(height: 16),
          _buildContinueChat(continueChat),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGreetingCard(Map<String, dynamic> feed) {
    final name = UserSession.name ?? 'there';
    final energy = feed['energy_score'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning, $name', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(feed['greeting_line'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
            if (feed['caution_line'] != null) ...[
              const SizedBox(height: 6),
              Text(feed['caution_line'], style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (energy != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentSaffron),
                  const SizedBox(width: 6),
                  Text('Overall energy: $energy/10', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
                child: const Text('Ask AI astrologer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysHighlights(Map<String, dynamic> ratings) {
    const labels = {
      'love': 'Love', 'career': 'Career', 'money': 'Money',
      'health': 'Health', 'family': 'Family',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's highlights", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...labels.entries.map((e) {
              final score = (ratings[e.key] ?? 0) as int;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(e.value, style: Theme.of(context).textTheme.bodyMedium)),
                    ...List.generate(5, (i) => Icon(
                          i < score ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: i < score ? AppTheme.accentSaffron : const Color(0xFFD8D5E6),
                        )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaCard(Map<String, dynamic> dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current dasha', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text('${dasha['mahadasha'] ?? '--'} mahadasha', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${dasha['antardasha'] ?? '--'} antardasha', style: Theme.of(context).textTheme.bodyMedium),
            if (dasha['next_change_date'] != null) ...[
              const SizedBox(height: 10),
              Text('Next major change: ${dasha['next_change_date']}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyCard(Map<String, dynamic> lucky) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's lucky", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                if (lucky['color'] != null) _LuckyItem(icon: Icons.circle, label: 'Color', value: lucky['color']),
                if (lucky['number'] != null) _LuckyItem(icon: Icons.tag, label: 'Number', value: '${lucky['number']}'),
                if (lucky['best_time'] != null) _LuckyItem(icon: Icons.schedule, label: 'Best time', value: lucky['best_time']),
                if (lucky['avoid'] != null) _LuckyItem(icon: Icons.block, label: 'Avoid', value: lucky['avoid']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions(Map<String, dynamic> categories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick questions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.keys.map((category) {
                return ActionChip(
                  label: Text(category[0].toUpperCase() + category.substring(1)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(initialCategory: category)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItems(Map<String, dynamic> feedItems) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your feed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (feedItems['today'] != null) _FeedRow(label: 'Today', text: feedItems['today']),
            if (feedItems['this_week'] != null) _FeedRow(label: 'This week', text: feedItems['this_week']),
            if (feedItems['upcoming'] != null) _FeedRow(label: 'Upcoming', text: feedItems['upcoming']),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommended(List<dynamic> recommended) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...recommended.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item['label'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueChat(Map<String, dynamic> continueChat) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: const Text('Continue previous chat', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('"${continueChat['question']}"'),
        trailing: const Icon(Icons.arrow_forward, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(initialCategory: continueChat['category'])),
        ),
      ),
    );
  }
}

class _LuckyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LuckyItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
}

class _FeedRow extends StatelessWidget {
  final String label;
  final String text;
  const _FeedRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
