import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';

/// Sends and verifies an OTP via Firebase Phone Auth, then registers the
/// user with the backend using the resulting verified ID token (see
/// auth_service.py -- the backend never trusts a client-supplied phone
/// number directly for this flow).
///
/// PLATFORM NOTE: Firebase Phone Auth requires the native setup described
/// in notification_service.dart (same Firebase project), PLUS enabling
/// "Phone" as a sign-in provider in Firebase Console -> Authentication ->
/// Sign-in method. Without that, sending the OTP will fail with a clear
/// Firebase error rather than silently doing nothing.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber; // full E.164 format, e.g. "+919876543210"
  final String? name;
  final String? gender;
  final String languagePref;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.name,
    this.gender,
    required this.languagePref,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _sendingOtp = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _sendingOtp = true;
      _error = null;
    });

    if (kIsWeb) {
      setState(() {
        _error = 'Phone OTP verification is not supported in this web preview. Test on Android/iOS.';
        _sendingOtp = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android auto-retrieval can complete verification without the
          // user typing anything -- handle that case by signing in directly.
          await _completeSignIn(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _error = e.message ?? 'Could not send OTP. Please check the number and try again.';
              _sendingOtp = false;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _sendingOtp = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not send OTP: $e';
          _sendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.trim().length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await _completeSignIn(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Invalid code. Please try again.';
        _verifying = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Verification failed: $e';
        _verifying = false;
      });
    }
  }

  Future<void> _completeSignIn(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();

      final user = await ApiService.registerWithVerifiedPhone(
        idToken: idToken!,
        name: widget.name,
        gender: widget.gender,
        languagePref: widget.languagePref,
      );

      await UserSession.setUser(
        id: user['id'],
        userName: user['name'],
        phone: user['phone_number'],
        language: widget.languagePref,
      );

      NotificationService.requestPermissionAndRegister(user['id']);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Registration failed: $e';
          _verifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (_sendingOtp)
              const Center(child: CircularProgressIndicator())
            else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(counterText: ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppTheme.warning)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyOtp,
                  child: _verifying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _sendingOtp ? null : _sendOtp,
                  child: const Text('Resend code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
