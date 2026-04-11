import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';

class NewMemberScreen extends StatefulWidget {
  final String userName;
  const NewMemberScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<NewMemberScreen> createState() => _NewMemberScreenState();
}

class _NewMemberScreenState extends State<NewMemberScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _confettiController;
  late AnimationController _headerController;
  late AnimationController _featuresController;
  late AnimationController _buttonController;

  late Animation<double> _bgAnim;
  late Animation<double> _emojiScale;
  late Animation<double> _emojiOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _featuresOpacity;
  late Animation<Offset> _featuresSlide;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  final List<_Confetti> _confettis = [];
  final Random _random = Random();

  final List<Map<String, dynamic>> _features = [
    {'icon': Icons.camera_alt_rounded, 'title': 'Scan Notes', 'desc': 'Capture & digitize handwritten notes instantly'},
    {'icon': Icons.psychology_rounded, 'title': 'AI Analysis', 'desc': 'Get smart summaries powered by Groq AI'},
    {'icon': Icons.quiz_rounded, 'title': 'Smart Quizzes', 'desc': 'Test your knowledge with AI-generated quizzes'},
    {'icon': Icons.timer_rounded, 'title': 'Study Timer', 'desc': 'Track your study sessions efficiently'},
  ];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 40; i++) {
      _confettis.add(_Confetti(
        x: _random.nextDouble(),
        y: _random.nextDouble() - 0.5,
        speed: _random.nextDouble() * 0.3 + 0.1,
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * pi * 2,
        color: [
          const Color(0xFF8B5CF6),
          const Color(0xFF6366F1),
          const Color(0xFFFBBF24),
          const Color(0xFF10B981),
          const Color(0xFFEF4444),
          const Color(0xFF3B82F6),
        ][_random.nextInt(6)],
      ));
    }

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _confettiController = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat();

    _headerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _emojiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _featuresController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _featuresOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeOut),
    );
    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _featuresController, curve: Curves.easeOut));

    _buttonController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _featuresController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _confettiController.dispose();
    _headerController.dispose();
    _featuresController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  String _getFirstName() {
    final parts = widget.userName.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : widget.userName;
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
                  center: Alignment(0.0, -0.3 + _bgAnim.value * 0.3),
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1B2D69).withOpacity(0.5),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _ConfettiPainter(
                confettis: _confettis,
                progress: _confettiController.value,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Emoji celebration
                  AnimatedBuilder(
                    animation: _headerController,
                    builder: (context, child) => Transform.scale(
                      scale: _emojiScale.value,
                      child: Opacity(opacity: _emojiOpacity.value, child: child),
                    ),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF111118),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 40, spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: const Text(
                        'Welcome to NEXUS,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SlideTransition(
                    position: _nameSlide,
                    child: FadeTransition(
                      opacity: _nameOpacity,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                        ).createShader(bounds),
                        child: Text(
                          _getFirstName() + '! 🚀',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'Your AI-powered study companion is ready.\nHere\'s what you can do:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Features
                  SlideTransition(
                    position: _featuresSlide,
                    child: FadeTransition(
                      opacity: _featuresOpacity,
                      child: Column(
                        children: _features.asMap().entries.map((entry) {
                          return _buildFeatureCard(
                            entry.value['icon'],
                            entry.value['title'],
                            entry.value['desc'],
                            entry.key,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Get Started button
                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonOpacity,
                      child: GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const HomeScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 600),
                          ),
                              (route) => false,
                        ),
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
                                blurRadius: 25, offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Learning!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.rocket_launch_rounded,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                        ),
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
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, int index) {
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFF6366F1),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors[index % colors.length].withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: colors[index % colors.length].withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors[index % colors.length], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: colors[index % colors.length].withOpacity(0.5), size: 16),
        ],
      ),
    );
  }
}

class _Confetti {
  double x, y, speed, size, rotation;
  Color color;
  _Confetti({
    required this.x, required this.y, required this.speed,
    required this.size, required this.rotation, required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confettis;
  final double progress;

  _ConfettiPainter({required this.confettis, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confettis) {
      final y = (c.y + progress * c.speed) % 1.2;
      if (y < 0) continue;
      final paint = Paint()..color = c.color.withOpacity(0.7);
      canvas.save();
      canvas.translate(c.x * size.width, y * size.height);
      canvas.rotate(c.rotation + progress * 3);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}