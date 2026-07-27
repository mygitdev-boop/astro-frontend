import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';

/// Registration: name + phone + language. Creates the user and goes
/// straight to the home dashboard -- birth details / Kundli generation
/// happens later, whenever the user chooses (see birth_details_screen.dart,
/// launched from Home/Kundli/Profile with a "generate your kundli" prompt).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  String _language = 'en';
  String? _gender;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiService.createUser(
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        gender: _gender,
        languagePref: _language,
      );
      await UserSession.setUser(
        id: user['id'],
        userName: user['name'],
        phone: user['phone_number'],
        language: _language,
      );

      // Fire-and-forget -- notification setup shouldn't block getting the
      // user into the app, and fails silently if Firebase isn't configured
      // yet (see notification_service.dart for what's needed).
      NotificationService.requestPermissionAndRegister(user['id']);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _phoneController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 96,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.nights_stay_rounded, size: 56, color: AppTheme.primaryBrown),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(height: 6),
                Center(child: Text(AppConfig.appTagline, style: Theme.of(context).textTheme.bodyMedium)),
                const SizedBox(height: 32),
                const Text('Choose your language', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ChoiceChipPill(
                      label: 'English',
                      selected: _language == 'en',
                      onTap: () => setState(() => _language = 'en'),
                    ),
                    const SizedBox(width: 12),
                    _ChoiceChipPill(
                      label: 'हिन्दी',
                      selected: _language == 'hi',
                      onTap: () => setState(() => _language = 'hi'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ChoiceChipPill(
                      label: 'Male',
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                    const SizedBox(width: 12),
                    _ChoiceChipPill(
                      label: 'Female',
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                    const SizedBox(width: 12),
                    _ChoiceChipPill(
                      label: 'Other',
                      selected: _gender == 'other',
                      onTap: () => setState(() => _gender = 'other'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppTheme.warning)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (canContinue && !_loading) ? _register : null,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChipPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryBrown : const Color(0xFFF0E4D3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
