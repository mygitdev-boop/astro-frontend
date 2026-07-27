import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'kundli_screen.dart';
import 'compatibility_screen.dart';
import 'yogas_doshas_screen.dart';
import 'divisional_charts_screen.dart';

/// Search/discovery screen. Terms that map to a specific screen navigate
/// there directly; anything else opens Chat with the term pre-filled as
/// a question, ready to send.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = [];

  static const _popularSearches = [
    'Marriage', 'Career', 'Kundli', 'Compatibility', 'Yogas', 'Doshas',
    'Dasha', 'Divisional charts', 'Nakshatra', 'Remedies',
  ];

  static const _keyRecentSearches = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recentSearches = prefs.getStringList(_keyRecentSearches) ?? []);
  }

  Future<void> _saveRecentSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [term, ..._recentSearches.where((s) => s != term)].take(10).toList();
    await prefs.setStringList(_keyRecentSearches, updated);
    setState(() => _recentSearches = updated);
  }

  void _handleSearch(String term) {
    if (term.trim().isEmpty) return;
    _saveRecentSearch(term.trim());

    final lower = term.trim().toLowerCase();

    // Direct-navigation terms -- these map to a specific screen rather
    // than a chat question.
    if (lower.contains('kundli') || lower.contains('birth chart')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KundliScreen()));
    } else if (lower.contains('compatib') || lower.contains('match')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompatibilityScreen()));
    } else if (lower.contains('yoga') || lower.contains('dosha')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const YogasDoshasScreen()));
    } else if (lower.contains('divisional') || lower.contains('navamsa') || lower.contains('dasamsa')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DivisionalChartsScreen()));
    } else {
      // Everything else -- open Chat with the term pre-filled as a question.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(initialQuestion: term.trim())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search anything...',
            border: InputBorder.none,
          ),
          onSubmitted: _handleSearch,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Popular searches', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((term) {
              return ActionChip(
                label: Text(term),
                onPressed: () => _handleSearch(term),
              );
            }).toList(),
          ),
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ..._recentSearches.map((term) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, size: 18, color: AppTheme.textSecondary),
                    title: Text(term),
                    trailing: const Icon(Icons.arrow_forward, size: 16),
                    onTap: () => _handleSearch(term),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
