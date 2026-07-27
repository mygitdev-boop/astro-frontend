import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_markdown_text.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final _personA = _PersonInput(label: 'Your details');
  final _personB = _PersonInput(label: "Partner's details");

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _personA.dispose();
    _personB.dispose();
    super.dispose();
  }

  Future<void> _checkCompatibility() async {
    if (!_personA.isComplete || !_personB.isComplete) {
      setState(() => _error = 'Please complete both people\'s birth details.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ApiService.checkCompatibility(
        personA: _personA.toPayload(),
        personB: _personB.toPayload(),
        language: UserSession.languagePref,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compatibility')),
      body: _result != null ? _buildResult() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter both birth details to see your Guna Milan compatibility score.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _PersonForm(person: _personA),
          const SizedBox(height: 20),
          _PersonForm(person: _personB),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.warning)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _checkCompatibility,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Check compatibility'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final guna = _result!['guna_milan'];
    final kootas = guna['kootas'] as Map<String, dynamic>;
    final total = guna['total_score'];
    final totalMax = guna['total_max'];
    final percentage = guna['percentage'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('${_result!['person_a_moon_sign']} + ${_result!['person_b_moon_sign']}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100, width: 100,
                      child: CircularProgressIndicator(
                        value: (percentage as num) / 100,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF0E4D3),
                        color: percentage >= 60 ? AppTheme.success : AppTheme.accentOrange,
                      ),
                    ),
                    Text('$percentage%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$total / $totalMax Gunas', style: Theme.of(context).textTheme.bodyMedium),
                if (guna['nadi_dosha'] == true || guna['bhakoot_dosha'] == true) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (guna['nadi_dosha'] == true) _DoshaChip(label: 'Nadi Dosha'),
                      if (guna['bhakoot_dosha'] == true) _DoshaChip(label: 'Bhakoot Dosha'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...kootas.entries.map((e) {
                  final info = e.value as Map<String, dynamic>;
                  final label = e.key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
                        Text('${info['score']} / ${info['max']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (_result!['explanation'] != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Our advice', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  AiMarkdownText(data: _result!['explanation']),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _result = null),
          child: const Text('Check another match'),
        ),
      ],
    );
  }
}

class _DoshaChip extends StatelessWidget {
  final String label;
  const _DoshaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.accentOrangeLight, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

/// Holds one person's birth detail form state.
class _PersonInput {
  final String label;
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final cityController = TextEditingController();
  CityResult? selectedCity;

  _PersonInput({required this.label});

  bool get isComplete => dateController.text.isNotEmpty && timeController.text.isNotEmpty && selectedCity != null;

  Map<String, dynamic> toPayload() => {
        'date': dateController.text,
        'time': timeController.text,
        'tz_offset_hours': 5.5,
        'latitude': selectedCity!.latitude,
        'longitude': selectedCity!.longitude,
      };

  void dispose() {
    dateController.dispose();
    timeController.dispose();
    cityController.dispose();
  }
}

class _PersonForm extends StatefulWidget {
  final _PersonInput person;
  const _PersonForm({required this.person});

  @override
  State<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<_PersonForm> {
  List<CityResult> _suggestions = [];
  bool _searching = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime(1998, 1, 1), firstDate: DateTime(1930), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        widget.person.dateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (picked != null) {
      setState(() {
        widget.person.timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _onCityChanged(String query) async {
    widget.person.selectedCity = null;
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await GeocodingService.searchCity(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: p.dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Date of birth', suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: p.timeController,
              readOnly: true,
              onTap: _pickTime,
              decoration: const InputDecoration(labelText: 'Time of birth', suffixIcon: Icon(Icons.access_time_outlined, size: 16)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: p.cityController,
              decoration: InputDecoration(
                labelText: 'Birth city',
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                    : (p.selectedCity != null ? const Icon(Icons.check_circle, color: AppTheme.success, size: 18) : null),
              ),
              onChanged: _onCityChanged,
            ),
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.borderDark
                      : const Color(0xFFF0E4D3)),
                ),
                child: Column(
                  children: _suggestions.map((city) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, size: 16),
                      title: Text(city.displayLabel, style: const TextStyle(fontSize: 13)),
                      onTap: () => setState(() {
                        p.selectedCity = city;
                        p.cityController.text = city.displayLabel;
                        _suggestions = [];
                      }),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
