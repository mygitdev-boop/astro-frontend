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

  static const _zodiacSymbols = {
    'Aries': '♈', 'Taurus': '♉', 'Gemini': '♊', 'Cancer': '♋',
    'Leo': '♌', 'Virgo': '♍', 'Libra': '♎', 'Scorpio': '♏',
    'Sagittarius': '♐', 'Capricorn': '♑', 'Aquarius': '♒', 'Pisces': '♓',
  };

  Widget _buildResult() {
    final guna = _result!['guna_milan'];
    final kootas = guna['kootas'] as Map<String, dynamic>;
    final total = guna['total_score'];
    final totalMax = guna['total_max'];
    final percentage = guna['percentage'];
    final signA = _result!['person_a_moon_sign'];
    final signB = _result!['person_b_moon_sign'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBrown, AppTheme.primaryBrownDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ZodiacAvatar(symbol: _zodiacSymbols[signA] ?? '✦', label: signA ?? '--'),
                  const SizedBox(width: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 90, width: 90,
                        child: CircularProgressIndicator(
                          value: (percentage as num) / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          color: percentage >= 60 ? AppTheme.success : AppTheme.accentYellow,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$percentage%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Match', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _ZodiacAvatar(symbol: _zodiacSymbols[signB] ?? '✦', label: signB ?? '--'),
                ],
              ),
              const SizedBox(height: 14),
              Text('$total / $totalMax Gunas', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
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

class _ZodiacAvatar extends StatelessWidget {
  final String symbol;
  final String label;
  const _ZodiacAvatar({required this.symbol, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white24,
          child: Text(symbol, style: const TextStyle(fontSize: 24, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
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
