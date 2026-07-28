import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'add_family_member_screen.dart';
import 'family_member_detail_screen.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  List<dynamic> _members = [];
  bool _loading = true;
  String? _error;

  static const _relationIcons = {
    'father': Icons.man,
    'mother': Icons.woman,
    'wife': Icons.favorite,
    'husband': Icons.favorite,
    'son': Icons.boy,
    'daughter': Icons.girl,
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
      final result = await ApiService.getFamilyMembers(UserSession.userId!);
      setState(() => _members = result['members'] ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAddPressed() async {
    // No client-side premium pre-check here -- UserSession.isPremium doesn't
    // know about bonus ad-unlock credits. The actual POST /family call is
    // the real gate; AddFamilyMemberScreen handles a 403 by offering the
    // ad-unlock/upgrade choice.
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFamilyMemberScreen()),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddPressed,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.warning), textAlign: TextAlign.center),
                  ),
                )
              : _members.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.family_restroom, size: 56, color: AppTheme.primaryBrown),
        const SizedBox(height: 20),
        Text(
          'Add your family',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Add Father, Mother, Wife, Children, and see everyone\'s dashboard in one place.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (!UserSession.isPremium) ...[
          const SizedBox(height: 16),
          Center(
            child: Chip(
              label: const Text('Premium feature'),
              backgroundColor: AppTheme.accentOrangeLight,
              avatar: const Icon(Icons.lock_outline, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: _members.map((m) {
        final icon = _relationIcons[m['relation']] ?? Icons.person_outline;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.accentOrangeLight,
              child: Icon(icon, color: AppTheme.accentOrange),
            ),
            title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${_capitalize(m['relation'] ?? '')} · ${m['moon_sign'] ?? '--'} Moon · ${m['ascendant'] ?? '--'} Ascendant',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyMemberDetailScreen(
                  memberId: m['id'],
                  name: m['name'],
                  relation: m['relation'],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
