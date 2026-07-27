import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';
import 'otp_verification_screen.dart';

/// Phone-first flow:
/// 1. Ask for phone number only.
/// 2. Check the backend -- if this phone is already registered, it's a
///    returning user: skip straight to OTP (mobile) or direct login (web),
///    no need to re-collect name/gender/language.
/// 3. If it's a new number, collect name/gender/language, then continue
///    to OTP verification (mobile) or direct registration (web).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = phone entry, 1 = name/gender/language (new users only)

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

  /// Assumes Indian numbers (+91) if no country code was typed -- adjust
  /// if you expand beyond the Indian market.
  String _formattedPhoneNumber() {
    final raw = _phoneController.text.trim();
    if (raw.startsWith('+')) return raw;
    return '+91$raw';
  }

  Future<void> _checkPhoneAndContinue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.checkPhoneExists(_formattedPhoneNumber());
      final exists = result['exists'] == true;

      if (exists) {
        await _loginExistingUser(result['user']);
      } else {
        if (mounted) setState(() => _step = 1);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginExistingUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      await UserSession.setUser(
        id: user['id'],
        userName: user['name'],
        phone: user['phone_number'],
        language: user['language_pref'] ?? 'en',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
      return;
    }

    // On mobile, still verify via OTP for security even though this is a
    // known number -- confirms it's really them. The backend's
    // register-with-phone endpoint already handles "existing user found"
    // by returning that user as-is, without needing name/gender again.
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: _formattedPhoneNumber(),
          languagePref: user['language_pref'] ?? 'en',
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (kIsWeb) {
      await _registerDirectly();
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: _formattedPhoneNumber(),
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          gender: _gender,
          languagePref: _language,
        ),
      ),
    );
  }

  Future<void> _registerDirectly() async {
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _step == 0 ? _buildPhoneStep() : _buildDetailsStep(),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    final canContinue = _phoneController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
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
          const SizedBox(height: 40),
          Text("What's your phone number?", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number', prefixText: '+91 '),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.warning)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canContinue && !_loading) ? _checkPhoneAndContinue : null,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text("You're new here -- let's set up your profile", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Your name'),
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
              onPressed: _loading ? null : _completeRegistration,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(height: 24),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBrown
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryBrown
                  : (isDark ? AppTheme.borderDark : const Color(0xFFF0E4D3))),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
