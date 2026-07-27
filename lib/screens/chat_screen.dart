import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? initialCategory;
  const ChatScreen({super.key, this.initialCategory});

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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
      });
    } catch (e) {
      setState(() => _messages.add(_ChatMessage('assistant', 'Sorry -- $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: const Color(0xFFEDEBF5)),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.4),
        ),
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
