import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import 'camera_screen.dart';
import 'text_input_screen.dart';
import 'study_timer_screen.dart';
import 'voice_summarizer_screen.dart';
import 'splash_screen.dart';
import 'profile_screen.dart';
import 'catalog_screen.dart'; // ADDED: Catalog

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");  // ADD THIS LINE
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS - AI Study Assistant',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _orbController;

  late Animation<double> _bgAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _card1Opacity;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Opacity;
  late Animation<Offset> _card2Slide;
  late Animation<double> _bottomOpacity;
  late Animation<Offset> _bottomSlide;

  final Random _random = Random();
  final List<_OrbData> _orbs = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 5; i++) {
      _orbs.add(_OrbData(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 80 + _random.nextDouble() * 120,
        opacity: 0.03 + _random.nextDouble() * 0.06,
        speed: 0.3 + _random.nextDouble() * 0.4,
      ));
    }

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _orbAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_orbController);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    ));

    _card1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    ));

    _card2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.82, curve: Curves.easeOut),
      ),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.55, 0.82, curve: Curves.easeOut),
    ));

    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<dynamic> _navigateWithResult(Widget screen) {
    HapticFeedback.mediumImpact();
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
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
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3 + _bgAnim.value * 0.6, -0.6),
                  radius: 1.4,
                  colors: [
                    const Color(0xFF3B1F8C).withOpacity(0.55),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Positioned(
              bottom: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.12 + _bgAnim.value * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _OrbPainter(orbs: _orbs, progress: _orbAnim.value),
            ),
          ),

          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(),
                    const SizedBox(height: 36),
                    _buildHeroSection(),
                    const SizedBox(height: 28),
                    _buildMainActions(),
                    const SizedBox(height: 28),
                    _buildToolsRow(),
                    const SizedBox(height: 28),
                    _buildStatsBar(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'NEXUS AI',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                'Study Assistant',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          // ADDED: Catalog button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigate(const CatalogScreen()),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF111118),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigate(const ProfileScreen()),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF111118),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.3),
        child: child,
      ),
      child: FadeTransition(
        opacity: _titleOpacity,
        child: SlideTransition(
          position: _titleSlide,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C1030), Color(0xFF111128)],
              ),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.5),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFB794F4)],
                            ).createShader(bounds),
                            child: const Text(
                              'NEXUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                          Text(
                            'AI STUDY ASSISTANT',
                            style: TextStyle(
                              color: const Color(0xFF8B5CF6).withOpacity(0.7),
                              fontSize: 10,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Transform your handwritten notes\ninto digital knowledge with AI',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildBadge(Icons.bolt_rounded, 'Groq AI', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.hearing_rounded, 'Whisper', const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.flash_on_rounded, 'Fast', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        FadeTransition(
          opacity: _card1Opacity,
          child: SlideTransition(
            position: _card1Slide,
            child: _buildActionCard(
              onTap: () async {
                await _navigateWithResult(const CameraScreen());
              },
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              icon: Icons.camera_alt_rounded,
              title: 'Scan Notes',
              subtitle: 'Point camera at handwritten notes',
              tag: 'OCR + AI',
              glow: const Color(0xFF8B5CF6),
              bordered: false,
            ),
          ),
        ),

        const SizedBox(height: 14),

        FadeTransition(
          opacity: _card2Opacity,
          child: SlideTransition(
            position: _card2Slide,
            child: _buildActionCard(
              onTap: () => _navigate(const TextInputScreen()),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF111128), Color(0xFF1A1A35)],
              ),
              icon: Icons.edit_note_rounded,
              title: 'Paste Text',
              subtitle: 'Type or paste text to analyze',
              tag: 'Manual',
              glow: const Color(0xFF4F46E5),
              bordered: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required VoidCallback onTap,
    required Gradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color glow,
    required bool bordered,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: bordered
              ? Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25))
              : Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsRow() {
    return SlideTransition(
      position: _bottomSlide,
      child: FadeTransition(
        opacity: _bottomOpacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOOLS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.timer_rounded,
                    label: 'Study\nTimer',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _navigate(const StudyTimerScreen()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.mic_rounded,
                    label: 'Voice\nSummarizer',
                    color: const Color(0xFF10B981),
                    onTap: () => _navigate(const VoiceSummarizerScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return SlideTransition(
      position: _bottomSlide,
      child: FadeTransition(
        opacity: _bottomOpacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              _buildStat('AI Engine', 'Groq', const Color(0xFF8B5CF6)),
              _buildDivider(),
              _buildStat('Voice', 'Whisper', const Color(0xFF6366F1)),
              _buildDivider(),
              _buildStat('Status', 'Active', const Color(0xFF10B981)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.07),
    );
  }
}

class _OrbData {
  double x, y, size, opacity, speed;
  _OrbData({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

class _OrbPainter extends CustomPainter {
  final List<_OrbData> orbs;
  final double progress;

  _OrbPainter({required this.orbs, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      final offset = sin((progress + i * 0.2) * 2 * pi) * 30;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(orb.opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(orb.x * size.width, orb.y * size.height + offset),
          radius: orb.size,
        ));
      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height + offset),
        orb.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}