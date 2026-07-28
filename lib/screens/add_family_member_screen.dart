import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/geocoding_service.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _cityController = TextEditingController();

  final double _tzOffset = 5.5;
  String _relation = 'father';
  String? _gender;

  CityResult? _selectedCity;
  List<CityResult> _citySuggestions = [];
  bool _searchingCity = false;

  bool _loading = false;
  String? _error;

  static const _relations = ['father', 'mother', 'wife', 'husband', 'son', 'daughter', 'other'];

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1970, 1, 1),
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
    if (_nameController.text.trim().isEmpty || _dateController.text.isEmpty || _timeController.text.isEmpty || _selectedCity == null) {
      setState(() => _error = 'Please fill in name, date of birth, time, and select a city from the list.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _attemptAdd();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        // Real premium gate -- offer the ad-unlock/upgrade choice rather
        // than just showing the raw error.
        await _handlePremiumGate();
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attemptAdd() async {
    await ApiService.addFamilyMember(
      userId: UserSession.userId!,
      name: _nameController.text.trim(),
      relation: _relation,
      gender: _gender,
      date: _dateController.text,
      time: _timeController.text,
      tzOffsetHours: _tzOffset,
      latitude: _selectedCity!.latitude,
      longitude: _selectedCity!.longitude,
      placeName: _selectedCity!.displayLabel,
    );
  }

  Future<void> _handlePremiumGate() async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Premium feature'),
        content: const Text(
          'Family Profiles is a premium feature. Upgrade for unlimited access, or watch a short ad to add this one family member for free.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.pop(context, 'ad'), child: const Text('Watch ad')),
          ElevatedButton(onPressed: () => Navigator.pop(context, 'upgrade'), child: const Text('Upgrade')),
        ],
      ),
    );

    if (choice == 'upgrade' && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
      return;
    }

    if (choice == 'ad') {
      await _watchAdAndRetry();
    }
  }

  Future<void> _watchAdAndRetry() async {
    if (!AdsService.isRewardedReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad is still loading -- please try again in a moment.')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    AdsService.showRewarded(
      onRewardEarned: () async {
        try {
          await ApiService.rewardPremiumUnlock(UserSession.userId!);
          await _attemptAdd(); // retry immediately, spending the credit we just earned
          if (!mounted) return;
          Navigator.of(context).pop(true);
        } catch (e) {
          if (mounted) setState(() => _error = e.toString());
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
      onNotReady: () {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad not available right now -- please try again shortly.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add family member')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              const Text('Relation', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relations.map((r) {
                  return ChoiceChip(
                    label: Text(r[0].toUpperCase() + r.substring(1)),
                    selected: _relation == r,
                    onSelected: (_) => setState(() => _relation = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
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
                  labelText: 'Search birth city',
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
                      : const Text('Add family member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
