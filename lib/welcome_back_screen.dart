import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';

class WelcomeBackScreen extends StatefulWidget {
  final String userName;
  const WelcomeBackScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _cardController;
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _buttonController;

  late Animation<double> _bgAnim;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoOpacity;
  late Animation<double> _greetOpacity;
  late Animation<Offset> _greetSlide;
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameSlide;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _floatAnim;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  final List<_Particle3D> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle3D(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        z: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 1,
        speed: _random.nextDouble() * 0.2 + 0.05,
        opacity: _random.nextDouble() * 0.6 + 0.1,
        color: _random.nextBool()
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF6366F1),
      ));
    }

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _floatController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _logoController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotate = Tween<double>(begin: -pi, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );
    _greetOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _greetSlide = Tween<Offset>(
      begin: const Offset(0, 0.5), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _cardController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _buttonController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _buttonController.forward();
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) _navigateToHome();
    });
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim, child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _cardController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  String _getFirstName() {
    final parts = widget.userName.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : widget.userName;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.5 + _bgAnim.value,
                    -0.3 + _bgAnim.value * 0.4,
                  ),
                  radius: 1.4,
                  colors: [
                    const Color(0xFF2D1B69).withOpacity(0.7),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5 - _bgAnim.value * 0.3, 0.5),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF1B2D69).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _Particle3DPainter(
                particles: _particles,
                progress: _particleController.value,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // ─── BUG 3 FIX: SingleChildScrollView prevents overflow ───────
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: child,
                        ),
                        child: AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) => Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_logoRotate.value),
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: child,
                              ),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _bgController,
                            builder: (context, child) => Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3D2B79),
                                    Color(0xFF1A0A40),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    blurRadius: 100,
                                    spreadRadius: 40,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hub_outlined,
                                size: 70,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      SlideTransition(
                        position: _greetSlide,
                        child: FadeTransition(
                          opacity: _greetOpacity,
                          child: Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SlideTransition(
                        position: _greetSlide,
                        child: FadeTransition(
                          opacity: _greetOpacity,
                          child: const Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SlideTransition(
                        position: _nameSlide,
                        child: FadeTransition(
                          opacity: _nameOpacity,
                          child: Padding(
                            // BUG 3 FIX: padding prevents name from touching edges
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6366F1),
                                  Color(0xFFA78BFA),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                widget.userName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // ─── BUG 3 FIX: cards use Flexible instead of fixed width ──
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(child: _buildInfoCard(Icons.bolt_rounded, 'AI Ready', '100%')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInfoCard(Icons.book_outlined, 'Study', 'Mode')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInfoCard(Icons.star_rounded, 'NEXUS', 'Pro')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ─────────────────────────────────────────────────────────

                      const SizedBox(height: 60),

                      SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: GestureDetector(
                              onTap: _navigateToHome,
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.5),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Let\'s Go!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _buttonOpacity,
                        child: Text(
                          'Taking you to NEXUS automatically...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BUG 3 FIX: removed fixed width, now uses Expanded from parent Row
  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle3D {
  double x, y, z, size, speed, opacity;
  Color color;
  _Particle3D({
    required this.x, required this.y, required this.z,
    required this.size, required this.speed,
    required this.opacity, required this.color,
  });
}

class _Particle3DPainter extends CustomPainter {
  final List<_Particle3D> particles;
  final double progress;

  _Particle3DPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final scale = 0.5 + p.z * 0.5;
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity * scale)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Particle3DPainter old) => true;
}