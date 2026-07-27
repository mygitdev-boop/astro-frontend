import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

/// "Go Premium" paywall screen. Shows Free vs Monthly (₹99) vs Yearly (₹999).
///
/// IMPORTANT SCOPE NOTE: this screen creates a Razorpay Order via the
/// backend (/create-order) but does NOT yet open Razorpay's actual payment
/// checkout UI -- that requires a platform-specific SDK:
///   - For a real Android/iOS build: the `razorpay_flutter` package, which
///     opens Razorpay's native checkout and returns payment_id/signature
///     directly to this app.
///   - For Flutter Web: Razorpay's web checkout.js needs JS interop (or a
///     redirect to a hosted checkout page), since it can't run inside
///     Flutter's canvas-based renderer the same way.
/// This screen is wired up to the point of creating the order; wiring the
/// actual checkout SDK is the next concrete step once you're building for
/// a real device/platform.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'yearly'; // default to the better-value plan
  bool _loading = false;
  String? _error;

  static const _benefits = [
    'Unlimited AI astrologer chat',
    'Detailed kundli & consultation reports',
    'Full yearly rashifal',
    'Ad-free experience',
    'Priority support',
  ];

  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ApiService.createOrder(
        userId: UserSession.userId!,
        planType: _selectedPlan,
      );
      if (!mounted) return;
      // Order created successfully on the backend -- see the scope note
      // above for why checkout doesn't open yet on this platform.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order created'),
          content: Text(
            'Order ID: ${order['order_id']}\nAmount: ₹${(order['amount'] as int) / 100}\n\n'
            'Payment checkout isn\'t wired up on this platform yet -- see the '
            'note in subscription_screen.dart for what\'s needed next.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
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
      appBar: AppBar(title: const Text('Go Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: AppTheme.accentOrange),
            const SizedBox(height: 12),
            Text('Unlock the power of astrology', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ..._benefits.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: AppTheme.success),
                      const SizedBox(width: 10),
                      Expanded(child: Text(b, style: Theme.of(context).textTheme.bodyLarge)),
                    ],
                  ),
                )),
            const SizedBox(height: 28),
            _PlanCard(
              label: 'Monthly',
              price: '₹99',
              period: '/ month',
              selected: _selectedPlan == 'monthly',
              onTap: () => setState(() => _selectedPlan = 'monthly'),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              label: 'Yearly',
              price: '₹999',
              period: '/ year',
              badge: 'Save 16%',
              selected: _selectedPlan == 'yearly',
              onTap: () => setState(() => _selectedPlan = 'yearly'),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized human astrologer consultations are charged separately.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.warning)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Subscribe -- ${_selectedPlan == 'monthly' ? '₹99/month' : '₹999/year'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentOrangeLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.accentOrange : const Color(0xFFF0E4D3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.accentOrange : AppTheme.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            Text(period, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
