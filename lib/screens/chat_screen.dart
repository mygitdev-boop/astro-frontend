import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/ai_markdown_text.dart';
import 'ai_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuestion;
  const ChatScreen({super.key, this.initialCategory, this.initialQuestion});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  _ChatMessage(this.role, this.content);
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  Map<String, dynamic> _quickQuestions = {};
  String? _selectedCategory;
  bool _sending = false;
  int? _questionsRemaining;
  int _exchangeCount = 0; // used to show an interstitial every few exchanges

  static const int _interstitialEveryNExchanges = 3;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (widget.initialQuestion != null) {
      _controller.text = widget.initialQuestion!;
    }
    _loadQuickQuestions();
  }

  Future<void> _loadQuickQuestions() async {
    try {
      final result = await ApiService.getQuickQuestions();
      setState(() => _quickQuestions = result);
    } catch (_) {
      // Non-critical -- chat still works without the quick-question chips
    }
  }

  Future<void> _send(String question) async {
    if (question.trim().isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage('user', question));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final result = await ApiService.chatWithAstrologer(
        userId: UserSession.userId!,
        question: question,
        category: _selectedCategory,
      );
      setState(() {
        _messages.add(_ChatMessage('assistant', result['answer']));
        _questionsRemaining = result['questions_remaining_today'];
        _exchangeCount++;
      });

      // Show an interstitial every few exchanges, free-tier only, and only
      // after the response is already showing (never interrupt mid-answer).
      if (!UserSession.isPremium && _exchangeCount % _interstitialEveryNExchanges == 0) {
        AdsService.showInterstitialIfReady();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        setState(() => _messages.removeLast()); // remove the user's message we optimistically added -- retry after ad
        _offerRewardedAdRetry(question);
      } else {
        setState(() => _messages.add(_ChatMessage('assistant', 'Sorry -- ${e.message}')));
      }
    } catch (e) {
      setState(() => _messages.add(_ChatMessage('assistant', 'Sorry -- $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _offerRewardedAdRetry(String pendingQuestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily free limit reached'),
        content: const Text(
          'Watch a short ad to unlock one more question today, or upgrade to Monthly/Yearly for unlimited chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _watchAdAndRetry(pendingQuestion);
            },
            child: const Text('Watch ad'),
          ),
        ],
      ),
    );
  }

  void _watchAdAndRetry(String pendingQuestion) {
    if (!AdsService.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet -- please try again in a moment.')),
      );
      return;
    }
    AdsService.showRewarded(
      onRewardEarned: () async {
        try {
          await ApiService.rewardBonusQuestion(UserSession.userId!);
          if (mounted) _send(pendingQuestion); // retry the original question now that a bonus is granted
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not grant bonus question: $e')),
            );
          }
        }
      },
      onNotReady: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready yet -- please try again in a moment.')),
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryQuestions = _selectedCategory != null
        ? (_quickQuestions[_selectedCategory] as List<dynamic>? ?? [])
        : <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI astrologer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiHistoryScreen()),
            ),
          ),
        ],
        bottom: _questionsRemaining != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$_questionsRemaining free questions left today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(categoryQuestions)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildMessageBubble(_messages[i]),
                  ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          if (!UserSession.isPremium) const BannerAdWidget(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<dynamic> categoryQuestions) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Text('Quick questions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickQuestions.keys.map((cat) {
            return ChoiceChip(
              label: Text(cat[0].toUpperCase() + cat.substring(1)),
              selected: _selectedCategory == cat,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
        if (categoryQuestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...categoryQuestions.map((q) => Card(
                child: ListTile(
                  title: Text(q.toString()),
                  trailing: const Icon(Icons.arrow_forward, size: 16),
                  onTap: () => _send(q.toString()),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.primaryBrown
            : Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUser
            ? null
            : Border.all(color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.borderDark
                : const Color(0xFFEDEBF5)),
      ),
      child: isUser
          ? Text(message.content, style: const TextStyle(color: Colors.white, height: 1.4))
          : AiMarkdownText(data: message.content),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    // Assistant messages get a small astrologer icon avatar alongside the bubble.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.accentOrangeLight,
            child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.accentOrange),
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Ask about career, love, money...'),
                onSubmitted: _send,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : () => _send(_controller.text),
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
