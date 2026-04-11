import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firestore_service.dart';

// ─────────────────────────────────────────────
//  NEXUS COLOR PALETTE
// ─────────────────────────────────────────────
const Color kBg         = Color(0xFF0A0A0A);
const Color kCard       = Color(0xFF121212);
const Color kCardAlt    = Color(0xFF1A1A1A);
const Color kPurple     = Color(0xFF8B5CF6);
const Color kPurpleDark = Color(0xFF7C3AED);
const Color kPurpleSub  = Color(0xFF2D1B69);
const Color kDivider    = Color(0xFF1F1F1F);
const Color kWhite      = Color(0xFFFFFFFF);
const Color kGrey       = Color(0xFF9CA3AF);
const Color kMuted      = Color(0xFF6B7280);
const Color kGreen      = Color(0xFF10B981);
const Color kOrange     = Color(0xFFF59E0B);

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({Key? key}) : super(key: key);

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen>
    with TickerProviderStateMixin {

  // ── Timer state ────────────────────────────
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFinished = false;
  bool _isLoadingStats = true; // shows loading indicator while fetching
  Timer? _timer;

  // ── Analytics state ────────────────────────
  int _todaySessions = 0;
  int _todayMinutes = 0;
  int _streakDays = 0;
  List<double> _weeklyMinutes = List.filled(7, 0);

  // ── Animation ─────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Preset durations ──────────────────────
  final List<int> _presets = [15, 25, 30, 45, 60, 90];

  // ── Current user UID ──────────────────────
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // ── Local cache keys (still used for instant display on load) ─────────────
  String get _todayKey {
    final n = DateTime.now();
    return '${_uid}_study_${n.year}_${n.month}_${n.day}';
  }
  String _dayKey(DateTime d) => '${_uid}_study_${d.year}_${d.month}_${d.day}';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Step 1: show local cache instantly (fast)
    _loadFromLocal();
    // Step 2: fetch from Firestore in background (cloud sync)
    _loadFromFirestore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── STEP 1: Load from SharedPreferences (instant, local cache) ───────────
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _todaySessions = prefs.getInt('${_todayKey}_sessions') ?? 0;
      _todayMinutes  = prefs.getInt('${_todayKey}_minutes')  ?? 0;

      final weekly = <double>[];
      for (int i = 6; i >= 0; i--) {
        final day = DateTime.now().subtract(Duration(days: i));
        weekly.add((prefs.getInt('${_dayKey(day)}_minutes') ?? 0).toDouble());
      }
      _weeklyMinutes = weekly;
    });
  }

  // ─── STEP 2: Load from Firestore (cloud, always up to date) ──────────────
  Future<void> _loadFromFirestore() async {
    try {
      // Get all timer session docs for this user
      final Map<String, int> allDays = await FirestoreService.getLast30DaysMinutes();

      if (!mounted) return;

      final now = DateTime.now();

      // Today's key in Firestore format
      final todayFirestoreKey = '${now.year}_${now.month}_${now.day}';

      // Get today's minutes from Firestore
      final todayMins = allDays[todayFirestoreKey] ?? 0;

      // Build weekly data (last 7 days) from Firestore
      final weekly = <double>[];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}_${day.month}_${day.day}';
        weekly.add((allDays[key] ?? 0).toDouble());
      }

      // Calculate streak from Firestore data
      int streak = 0;
      for (int i = 0; i < 30; i++) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}_${day.month}_${day.day}';
        final mins = allDays[key] ?? 0;
        if (mins > 0) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }

      // Get today's session count from Firestore
      final todaySessions = await _getTodaySessions();

      // Update local cache with Firestore data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_todayKey}_minutes', todayMins);
      await prefs.setInt('${_todayKey}_sessions', todaySessions);
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}_${day.month}_${day.day}';
        await prefs.setInt('${_dayKey(day)}_minutes', allDays[key] ?? 0);
      }

      if (!mounted) return;
      setState(() {
        _todayMinutes  = todayMins;
        _todaySessions = todaySessions;
        _weeklyMinutes = weekly;
        _streakDays    = streak;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Firestore load error: $e');
      // Fall back to local data if Firestore fails
      await _loadFromLocal();
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // ─── Get today's session count from Firestore ─────────────────────────────
  Future<int> _getTodaySessions() async {
    try {
      final now = DateTime.now();
      final dayKey = '${now.year}_${now.month}_${now.day}';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('timer_sessions')
          .doc(dayKey)
          .get();
      if (doc.exists) {
        return (doc.data()?['sessions'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Save session to BOTH Firestore and local cache ──────────────────────
  Future<void> _saveSession(int mins) async {
    // 1. Save to Firestore (cloud)
    try {
      await FirestoreService.saveTimerSession(minutes: mins);
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }

    // 2. Update local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_todayKey}_sessions',
        (prefs.getInt('${_todayKey}_sessions') ?? 0) + 1);
    await prefs.setInt('${_todayKey}_minutes',
        (prefs.getInt('${_todayKey}_minutes') ?? 0) + mins);

    // 3. Reload from Firestore to get accurate numbers
    await _loadFromFirestore();
  }

  // ── Timer controls ─────────────────────────
  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() { _isRunning = true; _isPaused = false; _isFinished = false; });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) { _onFinished(); }
      else { setState(() => _remainingSeconds--); }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() { _isRunning = false; _isPaused = true; });
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false; _isPaused = false;
      _isFinished = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _onFinished() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    HapticFeedback.heavyImpact();
    setState(() { _isRunning = false; _isFinished = true; _remainingSeconds = 0; });
    _saveSession(_selectedMinutes);
    _showCompletionDialog();
  }

  void _setDuration(int minutes) {
    if (_isRunning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isPaused = false; _isFinished = false;
    });
  }

  String get _formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _selectedMinutes * 60;
    return total == 0 ? 0 : 1 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTimerCircle(),
                    const SizedBox(height: 24),
                    _buildPresets(),
                    const SizedBox(height: 20),
                    _buildControls(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildWeeklyChart(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kBg,
        border: Border(bottom: BorderSide(color: kDivider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_rounded, color: kWhite, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: kPurple, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('NEXUS TIMER',
                    style: TextStyle(color: kPurple, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 2),
              const Text('Study Timer',
                  style: TextStyle(color: kWhite, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPurpleSub,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPurple.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$_streakDays day${_streakDays != 1 ? 's' : ''}',
                  style: const TextStyle(color: kPurple, fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isRunning ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: 240, height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isRunning)
              Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: kPurple.withOpacity(0.25), blurRadius: 40, spreadRadius: 5)],
                ),
              ),
            SizedBox(
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 8,
                backgroundColor: kCardAlt,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _isFinished ? kGreen : kPurple),
                strokeCap: StrokeCap.round,
              ),
            ),
            Container(
              width: 190, height: 190,
              decoration: BoxDecoration(
                color: kCard, shape: BoxShape.circle,
                border: Border.all(color: kDivider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isFinished)
                    const Icon(Icons.check_circle_rounded, color: kGreen, size: 44)
                  else ...[
                    Text(_formattedTime,
                        style: const TextStyle(color: kWhite, fontSize: 42,
                            fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(
                      _isRunning ? 'Focus Mode' : _isPaused
                          ? 'Paused' : '$_selectedMinutes min session',
                      style: TextStyle(
                        color: _isRunning ? kPurple : kGrey,
                        fontSize: 13, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration',
            style: TextStyle(color: kGrey, fontSize: 13,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _presets.map((min) {
            final selected = min == _selectedMinutes && !_isRunning;
            return GestureDetector(
              onTap: () => _setDuration(min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? kPurple : kCardAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? kPurple : kDivider),
                ),
                child: Text('${min}m',
                    style: TextStyle(
                      color: selected ? kWhite : kGrey,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        GestureDetector(
          onTap: _resetTimer,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: kCardAlt, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDivider),
            ),
            child: const Icon(Icons.refresh_rounded, color: kGrey, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: _isRunning ? _pauseTimer : _isPaused ? _startTimer : _startTimer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRunning
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [kPurple, kPurpleDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: (_isRunning
                      ? const Color(0xFFEF4444) : kPurple).withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: kWhite, size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isRunning ? 'Pause' : _isPaused ? 'Resume' : 'Start Session',
                    style: const TextStyle(color: kWhite, fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: _isRunning ? null : _showCustomTimePicker,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: kCardAlt, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDivider),
            ),
            child: const Icon(Icons.tune_rounded, color: kGrey, size: 24),
          ),
        ),
      ],
    );
  }

  // ─── Stats row — shows loading shimmer while fetching from Firestore ───────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: _isLoadingStats
          ? const Center(
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: kPurple, strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Syncing from cloud...',
                  style: TextStyle(color: kMuted, fontSize: 13)),
            ],
          ),
        ),
      )
          : Row(
        children: [
          _statItem(
            _todayMinutes >= 60
                ? '${(_todayMinutes / 60).toStringAsFixed(1)}h'
                : '${_todayMinutes}m',
            'Today', Icons.schedule_rounded, kPurple,
          ),
          Container(width: 1, height: 44, color: kDivider),
          _statItem('$_todaySessions', 'Sessions',
              Icons.check_circle_outline_rounded, kGreen),
          Container(width: 1, height: 44, color: kDivider),
          _statItem('$_streakDays', 'Day Streak',
              Icons.local_fire_department_rounded, kOrange),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(val, style: const TextStyle(color: kWhite, fontSize: 20,
          fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
    ]));
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = _weeklyMinutes.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Weekly Progress',
                style: TextStyle(color: kWhite, fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: kPurpleSub, borderRadius: BorderRadius.circular(20)),
              child: const Text('Last 7 Days',
                  style: TextStyle(color: kPurple, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal * 1.3 : 60,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kCardAlt,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}m',
                      const TextStyle(color: kWhite,
                          fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= 7) return const SizedBox();
                        final dayIdx =
                            (DateTime.now().weekday - 1 - (6 - i) + 7) % 7;
                        final isToday = i == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[dayIdx],
                              style: TextStyle(
                                color: isToday ? kPurple : kMuted,
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w700 : FontWeight.w400,
                              )),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 3 : 20,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: kDivider, strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isToday = i == 6;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: _weeklyMinutes[i],
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isToday
                            ? [kPurpleDark, kPurple]
                            : [kCardAlt, kCardAlt],
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomTimePicker() {
    int temp = _selectedMinutes;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => StatefulBuilder(
        builder: (context, setDs) => Dialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: kPurple, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('CUSTOM DURATION',
                      style: TextStyle(color: kPurple, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 12),
                const Text('Set Study Duration',
                    style: TextStyle(color: kWhite, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text('$temp min',
                    style: const TextStyle(color: kPurple, fontSize: 48,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: kPurple,
                    inactiveTrackColor: kCardAlt,
                    thumbColor: kPurple,
                    overlayColor: kPurple.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: temp.toDouble(), min: 5, max: 120, divisions: 23,
                    onChanged: (v) => setDs(() => temp = v.toInt()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('5 min', style: TextStyle(color: kMuted, fontSize: 12)),
                    Text('120 min',
                        style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: kCardAlt,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Cancel',
                            style: TextStyle(color: kGrey,
                                fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _setDuration(temp);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [kPurple, kPurpleDark]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(child: Text('Set Timer',
                            style: TextStyle(color: kWhite,
                                fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: kGreen, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Session Complete! 🔥',
                  style: TextStyle(color: kWhite, fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'You studied for $_selectedMinutes minutes.\nKeep the momentum going!',
                style: const TextStyle(color: kGrey, fontSize: 14,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                decoration: BoxDecoration(color: kPurpleSub,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dialogStat('$_todaySessions', 'Sessions'),
                    Container(width: 1, height: 30,
                        color: kPurple.withOpacity(0.3)),
                    _dialogStat('${_todayMinutes}m', 'Today'),
                    Container(width: 1, height: 30,
                        color: kPurple.withOpacity(0.3)),
                    _dialogStat('$_streakDays🔥', 'Streak'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: kCardAlt,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('Done',
                          style: TextStyle(color: kGrey,
                              fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _resetTimer();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [kPurple, kPurpleDark]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('Study Again',
                          style: TextStyle(color: kWhite,
                              fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStat(String val, String label) => Column(children: [
    Text(val, style: const TextStyle(color: kWhite, fontSize: 18,
        fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: kGrey, fontSize: 11)),
  ]);
}