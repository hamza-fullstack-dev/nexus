import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _buttonController;
  late AnimationController _floatController;

  late Animation<double> _bgAnim;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _card1Opacity;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Opacity;
  late Animation<Offset> _card2Slide;
  late Animation<double> _card3Opacity;
  late Animation<Offset> _card3Slide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _card1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    ));

    _card2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    ));

    _card3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    _card3Slide = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    ));

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start animations
    _contentController.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF0A0A0F),
                      const Color(0xFF1A0A3A),
                      _bgAnim.value,
                    )!,
                    const Color(0xFF0A0A0F),
                    Color.lerp(
                      const Color(0xFF0A0A0F),
                      const Color(0xFF0A1A3A),
                      _bgAnim.value,
                    )!,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Floating logo
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _bgAnim,
                        builder: (context, child) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2D1B69), Color(0xFF1A0A40)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withOpacity(0.3 + _bgAnim.value * 0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.hub_outlined,
                            size: 50,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFF8B5CF6),
                                    ],
                                  ).createShader(bounds),
                              child: const Text(
                                'Study Smarter\nNot Harder',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NEXUS transforms how you learn with\npowerful AI at your fingertips',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.5),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Feature cards
                    SlideTransition(
                      position: _card1Slide,
                      child: FadeTransition(
                        opacity: _card1Opacity,
                        child: _buildFeatureCard(
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF8B5CF6),
                          title: 'Scan & Digitize',
                          description:
                          'Point your camera at any handwritten notes and watch AI convert them instantly',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SlideTransition(
                      position: _card2Slide,
                      child: FadeTransition(
                        opacity: _card2Opacity,
                        child: _buildFeatureCard(
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xFF6366F1),
                          title: 'AI Quiz & Flashcards',
                          description:
                          'Generate smart quizzes and flashcards from your notes automatically',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SlideTransition(
                      position: _card3Slide,
                      child: FadeTransition(
                        opacity: _card3Opacity,
                        child: _buildFeatureCard(
                          icon: Icons.mic_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Voice Summarizer',
                          description:
                          'Record lectures and get AI-powered transcriptions and summaries',
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ✅ FIXED: Get Started button (removed duplicate text below)
                    FadeTransition(
                      opacity: _buttonOpacity,
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                            const LoginScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOut,
                                  )),
                                  child: child,
                                ),
                            transitionDuration:
                            const Duration(milliseconds: 400),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ✅ REMOVED: "Already have account? Sign in" text
                    // (since Get Started button already goes to Login)

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}