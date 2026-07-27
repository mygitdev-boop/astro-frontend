import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// Collects birth details and generates the Kundli. Reusable -- called
/// from the Home dashboard, Kundli tab, or Profile, whenever the user is
/// ready (registration no longer blocks on this).
class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _cityController = TextEditingController();

  final double _tzOffset = 5.5; // see geocoding_service.dart note on IST default

  CityResult? _selectedCity;
  List<CityResult> _citySuggestions = [];
  bool _searchingCity = false;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
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
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _onCityChanged(String query) async {
    _selectedCity = null;
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

  Future<void> _submit() async {
    if (_dateController.text.isEmpty || _timeController.text.isEmpty || _selectedCity == null) {
      setState(() => _error = 'Please fill in date of birth, time, and select a city from the list.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.submitBirthDetails(
        userId: UserSession.userId!,
        date: _dateController.text,
        time: _timeController.text,
        tzOffsetHours: _tzOffset,
        latitude: _selectedCity!.latitude,
        longitude: _selectedCity!.longitude,
        placeName: _selectedCity!.displayLabel,
      );
      final moonSign = result['chart']?['moon_sign']?['sign'];
      if (moonSign != null) await UserSession.setMoonSign(moonSign);
      if (!mounted) return;
      Navigator.of(context).pop(true); // signal success to caller
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate your kundli')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_selectedCity != null ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20) : null),
                ),
                onChanged: _onCityChanged,
              ),
              if (_citySuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.borderDark
                        : const Color(0xFFEDEBF5)),
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
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Generate my kundli'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
