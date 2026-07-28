import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'chat_screen.dart';
import 'birth_details_screen.dart';
import 'reports_screen.dart';
import 'search_screen.dart';
import 'learning_screen.dart';
import 'kundli_screen.dart';
import 'rashifal_screen.dart';
import 'compatibility_screen.dart';
import 'remedies_screen.dart';
import '../widgets/energy_gauge.dart';

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
  Map<String, dynamic>? _devotional;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadFestivals(); // independent of kundli -- always available
    _loadPanchang();  // also independent -- pure astronomy, no kundli needed
    _loadDevotional(); // also independent -- today's weekday deity/mantra
    UserSession.kundliUpdateSignal.addListener(_onKundliUpdated);
  }

  Future<void> _loadDevotional() async {
    try {
      final result = await ApiService.getTodaysDevotional();
      if (mounted) setState(() => _devotional = result);
    } catch (_) {
      // Non-critical -- skip silently if this fails
    }
  }

  @override
  void dispose() {
    UserSession.kundliUpdateSignal.removeListener(_onKundliUpdated);
    super.dispose();
  }

  void _onKundliUpdated() {
    if (mounted) _loadFeed();
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
      appBar: AppBar(
        title: const Text('Astro BhavishyaAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Astrology Learning',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearningScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
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
              runSpacing: 10,
              children: [
                if (tithi != null) _PanchangItem(icon: Icons.brightness_2_outlined, label: 'Tithi', value: '${tithi['name']} (${tithi['paksha']})'),
                if (p['nakshatra'] != null) _PanchangItem(icon: Icons.star_border_rounded, label: 'Nakshatra', value: p['nakshatra']),
                if (p['yoga'] != null) _PanchangItem(icon: Icons.all_inclusive, label: 'Yoga', value: p['yoga']),
                if (p['karana'] != null) _PanchangItem(icon: Icons.change_circle_outlined, label: 'Karana', value: p['karana']),
                if (p['sunrise'] != null) _PanchangItem(icon: Icons.wb_twilight, label: 'Sunrise', value: p['sunrise']),
                if (p['sunset'] != null) _PanchangItem(icon: Icons.nights_stay_outlined, label: 'Sunset', value: p['sunset']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevotionalCard() {
    final d = _devotional!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.self_improvement, size: 18, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Text("Today's devotion -- ${d['deity']}", style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            if (d['note'] != null)
              Text(d['note'], style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentOrangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['mantra_sanskrit'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['mantra_transliteration'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (d['mantra_meaning'] != null)
              Text(d['mantra_meaning'], style: Theme.of(context).textTheme.bodyMedium),
            if (d['chalisa_name'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('Also consider reading: ${d['chalisa_name']}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
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
        if (_devotional != null) ...[
          const SizedBox(height: 16),
          _buildDevotionalCard(),
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
        _buildGreetingCard(feed, lucky),
        const SizedBox(height: 16),
        _buildTodaysHighlights(ratings),
        const SizedBox(height: 16),
        _buildAskAiPromo(),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildDashaCard(dasha),
        if (_panchang != null) ...[
          const SizedBox(height: 16),
          _buildPanchangCard(),
        ],
        if (_devotional != null) ...[
          const SizedBox(height: 16),
          _buildDevotionalCard(),
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

  Widget _buildAskAiPromo() {
    return Container(
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask Astro Guru',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Get instant answers to your questions',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Ask Now'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Kundli', 'icon': Icons.auto_awesome_outlined, 'builder': () => const KundliScreen()},
      {'label': 'Rashifal', 'icon': Icons.calendar_today_outlined, 'builder': () => const RashifalScreen()},
      {'label': 'AI Chat', 'icon': Icons.chat_bubble_outline, 'builder': () => const ChatScreen()},
      {'label': 'Compatibility', 'icon': Icons.favorite_outline, 'builder': () => const CompatibilityScreen()},
      {'label': 'Reports', 'icon': Icons.description_outlined, 'builder': () => const ReportsScreen()},
      {'label': 'Remedies', 'icon': Icons.spa_outlined, 'builder': () => const RemediesScreen()},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
              children: actions.map((a) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => (a['builder'] as Widget Function())()),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.accentOrangeLight,
                        child: Icon(a['icon'] as IconData, color: AppTheme.accentOrange, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(a['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(Map<String, dynamic> feed, Map<String, dynamic> lucky) {
    final name = UserSession.name ?? 'there';
    final energy = feed['energy_score'];
    final now = DateTime.now();
    final dateLabel = '${now.day} ${_monthName(now.month)} ${now.year}, ${_weekdayName(now.weekday)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning, $name', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(feed['greeting_line'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.wb_sunny_rounded, color: AppTheme.accentYellow, size: 28),
              ],
            ),
            const SizedBox(height: 6),
            Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentOrangeLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (energy != null) ...[
                    EnergyGauge(score: (energy as num).toDouble(), size: 84),
                    const SizedBox(width: 18),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (lucky['color'] != null) _LuckyRow(icon: Icons.circle, label: 'Lucky Color', value: lucky['color']),
                        if (lucky['number'] != null) ...[
                          const SizedBox(height: 8),
                          _LuckyRow(icon: Icons.tag, label: 'Lucky Number', value: '${lucky['number']}'),
                        ],
                        if (lucky['best_time'] != null) ...[
                          const SizedBox(height: 8),
                          _LuckyRow(icon: Icons.schedule, label: 'Best Time', value: lucky['best_time']),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (feed['caution_line'] != null) ...[
              const SizedBox(height: 12),
              Text(feed['caution_line'], style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m - 1];

  String _weekdayName(int w) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
      ][w - 1];

  Widget _buildTodaysHighlights(Map<String, dynamic> ratings) {
    const items = [
      {'key': 'love', 'label': 'Love', 'icon': Icons.favorite, 'color': Color(0xFFE85D75)},
      {'key': 'career', 'label': 'Career', 'icon': Icons.work, 'color': Color(0xFF4A7FE8)},
      {'key': 'money', 'label': 'Money', 'icon': Icons.currency_rupee, 'color': Color(0xFF2E9E5B)},
      {'key': 'health', 'label': 'Health', 'icon': Icons.self_improvement, 'color': Color(0xFF3EBFB0)},
      {'key': 'family', 'label': 'Family', 'icon': Icons.groups, 'color': Color(0xFF9B6FE8)},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Highlights", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: items.map((item) {
                final score = (ratings[item['key']] ?? 0) as int;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: (item['color'] as Color).withValues(alpha: 0.12),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(item['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => Icon(
                            i < score ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 11,
                            color: i < score ? AppTheme.accentOrange : const Color(0xFFD8D5E6),
                          )),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaCard(Map<String, dynamic> dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.accentOrangeLight,
              child: Icon(Icons.public, color: AppTheme.accentOrange, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Dasha', style: Theme.of(context).textTheme.bodySmall),
                  Text('${dasha['mahadasha'] ?? '--'} Mahadasha', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${dasha['antardasha'] ?? '--'} Antardasha', style: const TextStyle(color: AppTheme.accentOrange, fontSize: 13)),
                ],
              ),
            ),
            if (dasha['next_change_date'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Next change', style: Theme.of(context).textTheme.bodySmall),
                  Text(dasha['next_change_date'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
                final label = categories[category]?['label'] ?? category;
                return ActionChip(
                  label: Text(label),
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
  final IconData icon;
  final String label;
  final String value;
  const _PanchangItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LuckyRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryBrown),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBrown)),
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
