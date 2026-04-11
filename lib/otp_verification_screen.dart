import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'new_member_screen.dart';
import 'dart:math';
import 'dart:convert';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userName;
  final String password; // NEW: received from signup screen

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.userName,
    required this.password, // NEW
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {

  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Stored OTP locally — no Firestore needed since no Firebase account yet
  String? _generatedOtp;
  DateTime? _otpExpiresAt;

  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _pinController;
  late AnimationController _shakeController;

  late Animation<double> _bgAnim;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _pinOpacity;
  late Animation<Offset> _pinSlide;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _setupAnimations();
    _contentController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _pinController.forward();
    });

    _startResendCountdown();
    _sendOtpEmail();
  }

  void _setupAnimations() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pinOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeOut),
    );
    _pinSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pinController, curve: Curves.easeOut));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  // ─── EMAILJS CONFIG ──────────────────────────────────────────────────────────
  static const _emailjsServiceId  = 'service_66b4o2j';
  static const _emailjsTemplateId = 'template_hhpcw1c';
  static const _emailjsPublicKey  = '_fFE6QYw6B5nWHrKf';
  static const _emailjsPrivateKey = 'YOUR_PRIVATE_KEY_HERE'; // replace this
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generates OTP and stores it in memory only — no Firebase account yet
  Future<void> _sendOtpEmail() async {
    try {
      final otp = (100000 + Random.secure().nextInt(900000)).toString();
      _generatedOtp = otp;
      _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  'service_66b4o2j',
          'template_id': 'template_hhpcw1c',
          'user_id':     '_fFE6QYw6B5nWHrKf',
          'accessToken': '4_MOgEi62TafQ1dKk9aca',
          'template_params': {
            'email':    widget.email,
            'to_name':  widget.userName,
            'passcode': otp,
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('EmailJS error: ${response.body}');
      }
    } catch (e) {
      debugPrint('OTP send error: $e');
    }
  }

  void _startResendCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
        }
      });
      return _resendCountdown > 0;
    });
  }

  /// Verifies OTP first, THEN creates Firebase account only if correct
  Future<void> _verify() async {
    final enteredCode = _controllers.map((c) => c.text).join();
    if (enteredCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check OTP was generated
      if (_generatedOtp == null || _otpExpiresAt == null) {
        setState(() => _errorMessage = 'No code found. Please request a new one.');
        _shakeController.forward(from: 0);
        return;
      }

      // Check expiry
      if (DateTime.now().isAfter(_otpExpiresAt!)) {
        setState(() => _errorMessage = 'Code expired. Please request a new one.');
        _shakeController.forward(from: 0);
        return;
      }

      // Check the code
      if (enteredCode != _generatedOtp) {
        setState(() => _errorMessage = 'Incorrect code. Please try again.');
        _shakeController.forward(from: 0);
        return;
      }

      // ✅ OTP correct — NOW create Firebase account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Update display name
      await credential.user?.updateDisplayName(widget.userName);

      // Navigate to new member / intro screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                NewMemberScreen(userName: widget.userName),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'An account already exists with this email.';
        } else {
          _errorMessage = 'Account creation failed. Please try again.';
        }
      });
      _shakeController.forward(from: 0);
    } catch (e) {
      setState(() => _errorMessage = 'Verification failed. Please try again.');
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() {
      _isResending = true;
      _canResend = false;
      _resendCountdown = 60;
      _errorMessage = null;
    });

    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();

    await _sendOtpEmail();

    if (mounted) {
      setState(() => _isResending = false);
      _startResendCountdown();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _bgController.dispose();
    _contentController.dispose();
    _pinController.dispose();
    _shakeController.dispose();
    super.dispose();
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
                  center: Alignment(0.0, -0.5 + _bgAnim.value * 0.4),
                  radius: 1.3,
                  colors: [
                    const Color(0xFF2D1B69).withOpacity(0.5),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111118),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              color: Color(0xFF8B5CF6),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NEXUS',
                              style: TextStyle(
                                color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          const Text(
                            'Verify\nEmail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 15,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'We sent a 6-digit code to\n'),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  SlideTransition(
                    position: _pinSlide,
                    child: FadeTransition(
                      opacity: _pinOpacity,
                      child: Column(
                        children: [
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
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444), fontSize: 13),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // OTP boxes
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                _errorMessage != null
                                    ? 10 * sin(_shakeAnim.value * pi * 4)
                                    : 0,
                                0,
                              ),
                              child: child,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, _buildOtpBox),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Verify button
                          GestureDetector(
                            onTap: _isLoading ? null : _verify,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                    const Color(0xFF8B5CF6).withOpacity(0.5),
                                    const Color(0xFF6366F1).withOpacity(0.5),
                                  ]
                                      : const [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Verify Code',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Resend
                          Center(
                            child: _canResend
                                ? GestureDetector(
                              onTap: _resendCode,
                              child: _isResending
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                                : RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: 'Resend code in '),
                                  TextSpan(
                                    text: '${_resendCountdown}s',
                                    style: const TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
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
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF111118),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF8B5CF6),
              width: 2,
            ),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          final code = _controllers.map((c) => c.text).join();
          if (code.length == 6) _verify();
        },
      ),
    );
  }
}