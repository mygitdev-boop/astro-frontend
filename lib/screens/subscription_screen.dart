import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../theme/app_theme.dart';

/// "Go Premium" paywall screen. Shows Free vs Monthly (₹99) vs Yearly (₹999),
/// and opens Razorpay's actual checkout UI to collect payment.
///
/// PLATFORM NOTE: razorpay_flutter only works on Android/iOS, not Flutter
/// Web (same limitation as google_mobile_ads). If you're testing with
/// `flutter run -d chrome`, tapping Subscribe will show an error instead
/// of opening checkout -- that's expected. Test on an Android
/// emulator/device to see the real payment flow.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'yearly'; // default to the better-value plan
  bool _loading = false;
  String? _error;

  Razorpay? _razorpay;
  String? _pendingOrderId; // set right before opening checkout, used on success

  static const _benefits = [
    'Unlimited AI astrologer chat',
    'Detailed kundli & consultation reports',
    'Full yearly rashifal',
    'Ad-free experience',
    'Priority support',
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (kIsWeb) {
      setState(() => _error = 'Payment checkout only works on Android/iOS, not in this web preview.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ApiService.createOrder(
        userId: UserSession.userId!,
        planType: _selectedPlan,
      );
      _pendingOrderId = order['order_id'];

      final options = {
        'key': order['razorpay_key_id'],
        'amount': order['amount'], // already in paise from the backend
        'order_id': order['order_id'],
        'currency': order['currency'],
        'name': 'Astro BhavishyaAI',
        'description': _selectedPlan == 'monthly' ? 'Monthly subscription' : 'Yearly subscription',
        'prefill': {
          'contact': UserSession.phoneNumber ?? '',
        },
      };

      _razorpay!.open(options);
      // Note: _loading stays true until one of the Razorpay callbacks fires --
      // the checkout UI takes over the screen at this point.
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService.verifyPayment(
        userId: UserSession.userId!,
        orderId: _pendingOrderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        planType: _selectedPlan,
      );
      UserSession.planType = _selectedPlan;
      if (!mounted) return;
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment successful'),
          content: Text('Your ${_selectedPlan == 'monthly' ? 'Monthly' : 'Yearly'} plan is now active.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close subscription screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Payment succeeded but activation failed: $e. Contact support with your payment ID: ${response.paymentId}';
      });
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Payment failed: ${response.message ?? 'Unknown error'}';
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Redirected to ${response.walletName} -- complete payment there.';
    });
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
          color: selected
              ? AppTheme.accentOrangeLight
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? AppTheme.accentOrange
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.borderDark
                      : const Color(0xFFF0E4D3)),
              width: selected ? 1.5 : 1),
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
