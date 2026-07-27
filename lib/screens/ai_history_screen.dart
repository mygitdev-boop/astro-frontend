import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  List<dynamic> _exchanges = [];
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
      final result = await ApiService.getChatHistory(UserSession.userId!);
      setState(() => _exchanges = result['exchanges'] ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                  ),
                )
              : _exchanges.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(
          'No questions asked yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your past questions to the AI astrologer will show up here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildList() {
    // Group by relative recency, matching the spec's "Yesterday / Last week" style.
    final now = DateTime.now();
    final Map<String, List<dynamic>> grouped = {};
    for (final e in _exchanges) {
      final askedAt = DateTime.tryParse(e['asked_at'] ?? '') ?? now;
      final diff = now.difference(askedAt).inDays;
      final bucket = diff == 0 ? 'Today' : diff == 1 ? 'Yesterday' : diff < 7 ? 'This week' : 'Earlier';
      grouped.putIfAbsent(bucket, () => []).add(e);
    }

    final order = ['Today', 'Yesterday', 'This week', 'Earlier'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final bucket in order)
          if (grouped[bucket] != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(bucket, style: Theme.of(context).textTheme.titleMedium),
            ),
            ...grouped[bucket]!.map((e) => _ExchangeCard(exchange: e)),
          ],
      ],
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  final Map<String, dynamic> exchange;
  const _ExchangeCard({required this.exchange});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(exchange['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            exchange['answer'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        trailing: exchange['category'] != null
            ? Chip(
                label: Text(exchange['category'], style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
      ),
    );
  }
}
