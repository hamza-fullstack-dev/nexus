import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'login_screen.dart';

// ============================================================
// SCREEN 1: Forgot Password OTP Screen
// ============================================================
class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final DateTime otpExpiresAt;

  const ForgotPasswordOtpScreen({
    Key? key,
    required this.email,
    required this.generatedOtp,
    required this.otpExpiresAt,
  }) : super(key: key);

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen>
    with TickerProviderStateMixin {

  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  bool _canResend = false;

  late String _currentOtp;
  late DateTime _currentOtpExpiresAt;

  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _shakeController;

  late Animation<double> _bgAnim;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _shakeAnim;

  static const _emailjsServiceId   = 'service_66b4o2j';
  static const _emailjsTemplateId  = 'template_hhpcw1c';
  static const _emailjsPublicKey   = '_fFE6QYw6B5nWHrKf';
  static const _emailjsAccessToken = '4_MOgEi62TafQ1dKk9aca';

  @override
  void initState() {
    super.initState();

    _currentOtp          = widget.generatedOtp;
    _currentOtpExpiresAt = widget.otpExpiresAt;

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _contentController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _shakeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _contentController.forward();
    _startCountdown(); // BUG 1 FIX: improved countdown logic
  }

  // ─── BUG 1 FIX: countdown now correctly shows button at 0 ─────────────────
  void _startCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _resendCountdown--;
      });

      if (_resendCountdown <= 0) {
        setState(() {
          _canResend = true;
        });
        return false; // stop the loop
      }
      return true; // keep counting
    });
  }
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() {
      _isResending = true;
      _canResend = false;
      _errorMessage = null;
    });

    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();

    try {
      final newOtp = (100000 + Random.secure().nextInt(900000)).toString();

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'accessToken': _emailjsAccessToken,
          'template_params': {
            'email':    widget.email,
            'to_name':  widget.email.split('@')[0],
            'passcode': newOtp,
          },
        }),
      );

      if (response.statusCode == 200) {
        _currentOtp          = newOtp;
        _currentOtpExpiresAt = DateTime.now().add(const Duration(minutes: 10));
      } else {
        if (mounted) setState(() => _errorMessage = 'Failed to resend code.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to resend code.');
    }

    if (mounted) {
      setState(() => _isResending = false);
      _startCountdown(); // restart countdown after resend
    }
  }

  Future<void> _verify() async {
    final enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (DateTime.now().isAfter(_currentOtpExpiresAt)) {
        setState(() => _errorMessage = 'Code expired. Please request a new one.');
        _shakeController.forward(from: 0);
        return;
      }

      if (enteredCode != _currentOtp) {
        setState(() => _errorMessage = 'Incorrect code. Please try again.');
        _shakeController.forward(from: 0);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChangePasswordScreen(email: widget.email),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0), end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }

    } catch (e) {
      setState(() => _errorMessage = 'Verification failed. Please try again.');
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _bgController.dispose();
    _contentController.dispose();
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
                  center: Alignment(0.0, -0.3 + _bgAnim.value * 0.3),
                  radius: 1.3,
                  colors: [
                    const Color(0xFF1B3A69).withOpacity(0.4),
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
                      width: 42, height: 42,
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
                    position: _slide,
                    child: FadeTransition(
                      opacity: _opacity,
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
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.key_rounded,
                                color: Color(0xFF8B5CF6), size: 32),
                          ),

                          const SizedBox(height: 24),

                          Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6), shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('NEXUS', style: TextStyle(
                              color: const Color(0xFF8B5CF6).withOpacity(0.8),
                              fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3,
                            )),
                          ]),

                          const SizedBox(height: 12),

                          const Text('Verify\nYour Email', style: TextStyle(
                            color: Colors.white, fontSize: 42,
                            fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
                          )),

                          const SizedBox(height: 8),

                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 15, height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFEF4444).withOpacity(0.3)),
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
                            const SizedBox(height: 24),
                          ],

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

                          GestureDetector(
                            onTap: _isLoading ? null : _verify,
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
                                  BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                      blurRadius: 20, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                    : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text('Verify Code', style: TextStyle(
                                        color: Colors.white, fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ─── BUG 1 FIX: shows proper button when countdown done ───
                          Center(
                            child: _canResend
                                ? GestureDetector(
                              onTap: _isResending ? null : _resendCode,
                              child: _isResending
                                  ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF8B5CF6), strokeWidth: 2),
                              )
                                  : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        color: Color(0xFF8B5CF6), size: 18),
                                    SizedBox(width: 8),
                                    Text('Send Code Again',
                                        style: TextStyle(
                                            color: Color(0xFF8B5CF6),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            )
                                : RichText(text: TextSpan(
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4), fontSize: 14),
                              children: [
                                const TextSpan(text: 'Resend code in '),
                                TextSpan(text: '${_resendCountdown}s',
                                    style: const TextStyle(color: Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.w600)),
                              ],
                            )),
                          ),
                          // ────────────────────────────────────────────────────────

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
      width: 48, height: 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 24,
            fontWeight: FontWeight.w700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF111118),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2)),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (val.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          final code = _controllers.map((c) => c.text).join();
          if (code.length == 6) _verify();
        },
      ),
    );
  }
}

// ============================================================
// SCREEN 2: Change Password Screen
// ============================================================
class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {

  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmVisible  = false;
  bool _isLoading       = false;
  String? _errorMessage;

  late AnimationController _bgController;
  late AnimationController _contentController;
  late Animation<double> _bgAnim;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _contentController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _contentController.forward();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PasswordSuccessScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Failed to reset password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      // ─── BUG 2 FIX: resizeToAvoidBottomInset prevents overflow when keyboard shows
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5 + _bgAnim.value, 0.0),
                  radius: 1.3,
                  colors: [
                    const Color(0xFF2D1B69).withOpacity(0.4),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              // BUG 2 FIX: SingleChildScrollView with physics allows content
              // to scroll when keyboard appears, preventing overflow
              physics: const ClampingScrollPhysics(),
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
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111118),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SlideTransition(
                      position: _slide,
                      child: FadeTransition(
                        opacity: _opacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF111118),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                  blurRadius: 30,
                                )],
                              ),
                              child: const Icon(Icons.lock_reset_rounded,
                                  color: Color(0xFF8B5CF6), size: 32),
                            ),

                            const SizedBox(height: 24),

                            Row(children: [
                              Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B5CF6), shape: BoxShape.circle,
                                  )),
                              const SizedBox(width: 8),
                              Text('NEXUS', style: TextStyle(
                                color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3,
                              )),
                            ]),

                            const SizedBox(height: 12),

                            const Text('New\nPassword', style: TextStyle(
                              color: Colors.white, fontSize: 42,
                              fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
                            )),

                            const SizedBox(height: 8),

                            Text('Create a strong new password for your account',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4), fontSize: 15),
                            ),

                            const SizedBox(height: 40),

                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity, padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFEF4444).withOpacity(0.3)),
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

                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'New Password',
                              hint: 'Min. 6 characters',
                              visible: _passwordVisible,
                              onToggle: () => setState(
                                      () => _passwordVisible = !_passwordVisible),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Please enter a password';
                                if (val.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildPasswordField(
                              controller: _confirmController,
                              label: 'Confirm Password',
                              hint: 'Re-enter password',
                              visible: _confirmVisible,
                              onToggle: () => setState(
                                      () => _confirmVisible = !_confirmVisible),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Please confirm your password';
                                if (val != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),

                            const SizedBox(height: 40),

                            GestureDetector(
                              onTap: _isLoading ? null : _changePassword,
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
                                  boxShadow: _isLoading ? [] : [BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                    blurRadius: 20, offset: const Offset(0, 8),
                                  )],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(width: 24, height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                      : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_rounded,
                                          color: Colors.white, size: 22),
                                      SizedBox(width: 10),
                                      Text('Change Password', style: TextStyle(
                                          color: Colors.white, fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // BUG 2 FIX: extra bottom padding so button never gets cut off
                            const SizedBox(height: 40),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          color: Colors.white.withOpacity(0.7), fontSize: 13,
          fontWeight: FontWeight.w600, letterSpacing: 0.5,
        )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2), fontSize: 16),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: const Color(0xFF8B5CF6).withOpacity(0.7), size: 20),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.3), size: 20,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFF111118),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444))),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCREEN 3: Password Success Screen
// ============================================================
class PasswordSuccessScreen extends StatefulWidget {
  const PasswordSuccessScreen({Key? key}) : super(key: key);

  @override
  State<PasswordSuccessScreen> createState() => _PasswordSuccessScreenState();
}

class _PasswordSuccessScreenState extends State<PasswordSuccessScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _checkController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _ringController;

  late Animation<double> _bgAnim;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _ringController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );
    _ringScale = Tween<double>(begin: 0.0, end: 2.5).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _checkController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeIn),
    );

    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _buttonController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ringController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _buttonController.forward();
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _goToLogin();
    });
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _checkController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _ringController.dispose();
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
                  center: const Alignment(0, 0),
                  radius: 1.4 + _bgAnim.value * 0.2,
                  colors: [
                    const Color(0xFF0D3D2A).withOpacity(0.6),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          // ─── BUG 2 FIX: wrap in SingleChildScrollView to prevent overflow ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          SizedBox(
                            width: 180, height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _ringController,
                                  builder: (context, _) => Transform.scale(
                                    scale: _ringScale.value,
                                    child: Opacity(
                                      opacity: _ringOpacity.value,
                                      child: Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: const Color(0xFF10B981), width: 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                AnimatedBuilder(
                                  animation: _checkController,
                                  builder: (context, child) => Transform.scale(
                                    scale: _checkScale.value,
                                    child: Opacity(opacity: _checkOpacity.value, child: child),
                                  ),
                                  child: Container(
                                    width: 110, height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.5),
                                          width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.4),
                                          blurRadius: 40, spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: Color(0xFF10B981), size: 55),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textOpacity,
                              child: Column(
                                children: [
                                  const Text('Password Reset!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white, fontSize: 34,
                                      fontWeight: FontWeight.w900, letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'A password reset link has been sent to your email.\nClick the link to set your new password.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 15, height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.3)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.mark_email_read_rounded,
                                          color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 8),
                                      Text('Check Your Email',
                                        style: TextStyle(
                                          color: const Color(0xFF10B981).withOpacity(0.9),
                                          fontSize: 13, fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),

                          SlideTransition(
                            position: _buttonSlide,
                            child: FadeTransition(
                              opacity: _buttonOpacity,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _goToLogin,
                                    child: Container(
                                      width: double.infinity, height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(
                                          color: const Color(0xFF8B5CF6).withOpacity(0.5),
                                          blurRadius: 25, offset: const Offset(0, 10),
                                        )],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded,
                                              color: Colors.white, size: 22),
                                          SizedBox(width: 10),
                                          Text('Sign In Now', style: TextStyle(
                                            color: Colors.white, fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Redirecting to Sign In automatically...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.2),
                                      fontSize: 12, letterSpacing: 0.5,
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
              ),
            ),
          ),
          // ────────────────────────────────────────────────────────────────────
        ],
      ),
    );
  }
}