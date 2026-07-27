import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';

/// First-run flow: phone number -> name -> birth details.
/// Ends by creating the user and generating their Kundli, then goes
/// straight to the home feed.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = welcome, 1 = phone+name, 2 = birth details

  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _placeController = TextEditingController();

  String _language = 'en';
  double _tzOffset = 5.5; // default IST -- covers the vast majority of users
  double? _latitude;
  double? _longitude;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1998, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      _timeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submitBirthDetails() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      setState(() => _error = 'Please fill in date of birth, time, and place.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create the user first
      final user = await ApiService.createUser(
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        languagePref: _language,
      );
      UserSession.setUser(
        id: user['id'],
        userName: user['name'],
        phone: user['phone_number'],
        language: _language,
      );

      // Then submit birth details -- this triggers Kundli generation server-side
      final result = await ApiService.submitBirthDetails(
        userId: user['id'],
        date: _dateController.text,
        time: _timeController.text,
        tzOffsetHours: _tzOffset,
        latitude: _latitude!,
        longitude: _longitude!,
        placeName: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
      );

      final moonSign = result['chart']?['moon_sign']?['sign'];
      UserSession.moonSignRashi = moonSign;

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
          child: _step == 0
              ? _buildWelcomeStep()
              : _step == 1
                  ? _buildPhoneStep()
                  : _buildBirthDetailsStep(),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.nights_stay_rounded, size: 72, color: AppTheme.primaryIndigo),
        const SizedBox(height: 24),
        Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          AppConfig.appTagline,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const Text('Choose your language', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LanguageChip(
              label: 'English',
              selected: _language == 'en',
              onTap: () => setState(() => _language = 'en'),
            ),
            const SizedBox(width: 12),
            _LanguageChip(
              label: 'हिन्दी',
              selected: _language == 'hi',
              onTap: () => setState(() => _language = 'hi'),
            ),
          ],
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Get started'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('What should we call you?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _phoneController.text.trim().isEmpty
                ? null
                : () => setState(() => _step = 2),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDetailsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Your birth details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'This is what powers your Kundli -- accuracy here matters, especially the time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timeController,
            readOnly: true,
            onTap: _pickTime,
            decoration: const InputDecoration(
              labelText: 'Time of birth',
              suffixIcon: Icon(Icons.access_time_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _placeController,
            decoration: const InputDecoration(labelText: 'Place of birth (city)'),
          ),
          const SizedBox(height: 16),
          // NOTE: this is a simplified lat/long entry for now. Before shipping,
          // replace with a place-autocomplete (e.g. Google Places) that resolves
          // city name -> lat/long/timezone automatically -- users won't know
          // their coordinates offhand.
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  onChanged: (v) => _latitude = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  onChanged: (v) => _longitude = double.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: search "[city name] latitude longitude" to find these.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.warning)),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submitBirthDetails,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Generate my kundli'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryIndigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryIndigo : const Color(0xFFEDEBF5)),
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
