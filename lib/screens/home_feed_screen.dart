import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'chat_screen.dart';
import 'birth_details_screen.dart';
import 'reports_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  Map<String, dynamic>? _feed;
  bool _loading = true;
  String? _error;
  bool _needsKundli = false;

  List<dynamic> _festivals = [];
  Map<String, dynamic>? _panchang;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadFestivals(); // independent of kundli -- always available
    _loadPanchang();  // also independent -- pure astronomy, no kundli needed
  }

  Future<void> _loadPanchang() async {
    try {
      final result = await ApiService.getTodaysPanchang();
      if (mounted) setState(() => _panchang = result);
    } catch (_) {
      // Non-critical -- skip silently if this fails
    }
  }

  Future<void> _loadFestivals() async {
    try {
      final result = await ApiService.getUpcomingFestivals(limit: 3);
      if (mounted) setState(() => _festivals = result['festivals'] ?? []);
    } catch (_) {
      // Non-critical -- silently skip if this fails, rest of the feed still works
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsKundli = false;
    });
    try {
      // Sync plan status too -- cheap call, keeps ad-free/premium state current
      // (e.g. right after subscribing, or if a plan expired since last check).
      try {
        final user = await ApiService.getUser(UserSession.userId!);
        UserSession.planType = user['plan_type'] ?? 'free';
      } catch (_) {
        // Non-critical -- feed still loads even if this sync fails
      }

      final feed = await ApiService.getHomeFeed(UserSession.userId!);
      setState(() => _feed = feed);
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
    if (result == true) _loadFeed(); // kundli was generated -- refresh the feed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astro BhavishyaAI')),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _needsKundli
                ? _buildNeedsKundli()
                : _error != null
                    ? _buildError()
                    : _buildFeed(),
      ),
      bottomNavigationBar: UserSession.isPremium ? null : const BannerAdWidget(),
    );
  }

  Widget _buildPanchangCard() {
    final p = _panchang!;
    final tithi = p['tithi'] as Map<String, dynamic>?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 18, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Text("Today's panchang", style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (tithi != null) _PanchangItem(label: 'Tithi', value: '${tithi['name']} (${tithi['paksha']})'),
                if (p['nakshatra'] != null) _PanchangItem(label: 'Nakshatra', value: p['nakshatra']),
                if (p['yoga'] != null) _PanchangItem(label: 'Yoga', value: p['yoga']),
                if (p['karana'] != null) _PanchangItem(label: 'Karana', value: p['karana']),
                if (p['sunrise'] != null) _PanchangItem(label: 'Sunrise', value: p['sunrise']),
                if (p['sunset'] != null) _PanchangItem(label: 'Sunset', value: p['sunset']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsKundli() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.auto_awesome_outlined, size: 56, color: AppTheme.primaryBrown),
        const SizedBox(height: 20),
        Text(
          'Generate your kundli to unlock your personalized feed',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Your daily energy score, highlights, dasha, and lucky elements are all based on your birth chart.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _openBirthDetails,
          child: const Text('Generate my kundli'),
        ),
        if (_panchang != null) ...[
          const SizedBox(height: 32),
          _buildPanchangCard(),
        ],
        if (_festivals.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildFestivalsCard(),
        ],
      ],
    );
  }

  Widget _buildFestivalsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_outlined, size: 18, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Text('Upcoming festivals', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ..._festivals.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          f['date'] ?? '',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            Text(f['significance'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
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
        if (_panchang != null) ...[
          const SizedBox(height: 16),
          _buildPanchangCard(),
        ],
        if (_festivals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFestivalsCard(),
        ],
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
                  const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentOrange),
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
                          color: i < score ? AppTheme.accentOrange : const Color(0xFFD8D5E6),
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
            ...recommended.map((item) => InkWell(
                  onTap: item['type'] == 'report' || item['type'] == 'upsell'
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['label'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                        if (item['type'] == 'report' || item['type'] == 'upsell')
                          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
                      ],
                    ),
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

class _PanchangItem extends StatelessWidget {
  final String label;
  final String value;
  const _PanchangItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
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
