import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';

/// First-run flow: name+phone+language (combined) -> birth details.
/// Ends by creating the user and generating their Kundli, then goes
/// straight to the home dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = name+phone+language (combined), 1 = birth details

  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _cityController = TextEditingController();

  String _language = 'en';

  // Default to IST -- this app targets the Indian market. See
  // geocoding_service.dart for the note on why we don't resolve a
  // per-city historical UTC offset yet.
  final double _tzOffset = 5.5;

  CityResult? _selectedCity;
  List<CityResult> _citySuggestions = [];
  bool _searchingCity = false;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _cityController.dispose();
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
      setState(() {
        _dateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _onCityChanged(String query) async {
    _selectedCity = null; // typing invalidates any prior selection
    if (query.trim().length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }
    setState(() => _searchingCity = true);
    final results = await GeocodingService.searchCity(query);
    if (!mounted) return;
    setState(() {
      _citySuggestions = results;
      _searchingCity = false;
    });
  }

  void _selectCity(CityResult city) {
    setState(() {
      _selectedCity = city;
      _cityController.text = city.displayLabel;
      _citySuggestions = [];
    });
  }

  Future<void> _submitBirthDetails() async {
    if (_dateController.text.isEmpty || _timeController.text.isEmpty || _selectedCity == null) {
      setState(() => _error = 'Please fill in date of birth, time, and select a city from the list.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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

      final result = await ApiService.submitBirthDetails(
        userId: user['id'],
        date: _dateController.text,
        time: _timeController.text,
        tzOffsetHours: _tzOffset,
        latitude: _selectedCity!.latitude,
        longitude: _selectedCity!.longitude,
        placeName: _selectedCity!.displayLabel,
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
          child: _step == 0 ? _buildDetailsStep() : _buildBirthDetailsStep(),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    final canContinue = _phoneController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.nights_stay_rounded, size: 56, color: AppTheme.primaryIndigo),
          const SizedBox(height: 16),
          Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(AppConfig.appTagline, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          const Text('Choose your language', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canContinue ? () => setState(() => _step = 1) : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Search your birth city',
              suffixIcon: _searchingCity
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_selectedCity != null
                      ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                      : null),
            ),
            onChanged: _onCityChanged,
          ),
          if (_citySuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEBF5)),
              ),
              child: Column(
                children: _citySuggestions.map((city) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18),
                    title: Text(city.displayLabel),
                    onTap: () => _selectCity(city),
                  );
                }).toList(),
              ),
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
