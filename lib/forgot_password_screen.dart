import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'forgot_password_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _contentController;
  late AnimationController _bgController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  late Animation<double> _bgAnim;

  // ─── EMAILJS CONFIG (same as your OTP screen) ─────────────────────────────
  static const _emailjsServiceId  = 'service_66b4o2j';
  static const _emailjsTemplateId = 'template_hhpcw1c';
  static const _emailjsPublicKey  = '_fFE6QYw6B5nWHrKf';
  static const _emailjsAccessToken = '4_MOgEi62TafQ1dKk9aca';
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _contentController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _contentController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  // ─── Generate OTP and send via EmailJS ────────────────────────────────────
  Future<String?> _sendOtpEmail(String email) async {
    try {
      final otp = (100000 + Random.secure().nextInt(900000)).toString();

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'accessToken': _emailjsAccessToken,
          'template_params': {
            'email':    email,
            'to_name':  email.split('@')[0],
            'passcode': otp,
          },
        }),
      );

      if (response.statusCode == 200) {
        return otp; // return generated OTP to pass to OTP screen
      } else {
        debugPrint('EmailJS error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('OTP send error: $e');
      return null;
    }
  }

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      // Send OTP via EmailJS directly — no Firebase email check needed
      final generatedOtp = await _sendOtpEmail(email);

      if (generatedOtp == null) {
        setState(() => _errorMessage = 'Failed to send code. Please try again.');
        return;
      }

      // Navigate to OTP screen passing email + generated OTP
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ForgotPasswordOtpScreen(
              email: email,
              generatedOtp: generatedOtp,
              otpExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
            ),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = 'Error: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.5),
                  radius: 1.2 + _bgAnim.value * 0.3,
                  colors: [
                    const Color(0xFF1B3A69).withOpacity(0.3),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111118),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF111118),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.lock_reset_rounded,
                                  color: Color(0xFF8B5CF6), size: 32),
                            ),

                            const SizedBox(height: 24),

                            Row(children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('NEXUS', style: TextStyle(
                                color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3,
                              )),
                            ]),

                            const SizedBox(height: 12),

                            const Text('Reset\nPassword', style: TextStyle(
                              color: Colors.white, fontSize: 42,
                              fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
                            )),

                            const SizedBox(height: 8),

                            Text(
                              'Enter your email and we\'ll send a 6-digit code to reset your password',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 15, height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 40),

                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFEF4444), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_errorMessage!,
                                      style: const TextStyle(
                                          color: Color(0xFFEF4444), fontSize: 13))),
                                ]),
                              ),
                              const SizedBox(height: 20),
                            ],

                            Text('Email Address', style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                            )),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please enter your email';
                                if (!val.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'your@email.com',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.2), fontSize: 16,
                                ),
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: const Color(0xFF8B5CF6).withOpacity(0.7), size: 20),
                                filled: true,
                                fillColor: const Color(0xFF111118),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF8B5CF6), width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                              ),
                            ),

                            const SizedBox(height: 32),

                            GestureDetector(
                              onTap: _isLoading ? null : _sendResetOtp,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity, height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [const Color(0xFF8B5CF6).withOpacity(0.5),
                                      const Color(0xFF6366F1).withOpacity(0.5)]
                                        : const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isLoading ? [] : [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                      blurRadius: 20, offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                      : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text('Send Code', style: TextStyle(
                                        color: Colors.white, fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: double.infinity, height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111118),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back_rounded,
                                        color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text('Back to Sign In', style: TextStyle(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}