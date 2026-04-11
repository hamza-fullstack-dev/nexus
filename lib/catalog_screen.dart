import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'firestore_service.dart';

// ─────────────────────────────────────────────
//  NEXUS COLOR PALETTE
// ─────────────────────────────────────────────
const Color _kBg        = Color(0xFF0A0A0F);
const Color _kCard      = Color(0xFF111118);
const Color _kCardAlt   = Color(0xFF1A1A24);
const Color _kPurple    = Color(0xFF8B5CF6);
const Color _kIndigo    = Color(0xFF6366F1);
const Color _kGreen     = Color(0xFF10B981);
const Color _kRed       = Color(0xFFEF4444);
const Color _kGrey      = Color(0xFF9CA3AF);
const Color _kMuted     = Color(0xFF6B7280);
const Color _kDivider   = Color(0xFF1F1F1F);
const Color _kWhite     = Color(0xFFFFFFFF);
const Color _kPurpleSub = Color(0xFF2D1B69);

// ═══════════════════════════════════════════════════════
//  MAIN CATALOG SCREEN
// ═══════════════════════════════════════════════════════
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);

    _entryController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3 + _bgAnim.value * 0.4, -0.5),
                  radius: 1.3,
                  colors: [
                    const Color(0xFF3B1F8C).withOpacity(0.4),
                    _kBg,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildSection(
                              label: 'QUIZ HISTORY',
                              icon: Icons.quiz_rounded,
                              color: _kPurple,
                              onViewAll: () => _navigate(const QuizHistoryScreen()),
                              child: _QuizPreviewCards(onViewAll: () => _navigate(const QuizHistoryScreen())),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              label: 'VOICE NOTES',
                              icon: Icons.mic_rounded,
                              color: _kGreen,
                              onViewAll: () => _navigate(const VoiceNotesHistoryScreen()),
                              child: _VoicePreviewCards(onViewAll: () => _navigate(const VoiceNotesHistoryScreen())),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              label: 'SCANNED NOTES',
                              icon: Icons.document_scanner_rounded,
                              color: _kIndigo,
                              onViewAll: () => _navigate(const ScannedNotesHistoryScreen()),
                              child: _ScannedPreviewCards(onViewAll: () => _navigate(const ScannedNotesHistoryScreen())),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              label: 'STUDY PROGRESS',
                              icon: Icons.bar_chart_rounded,
                              color: const Color(0xFFF59E0B),
                              onViewAll: () => _navigate(const StudyProgressScreen()),
                              child: _StudyProgressPreview(onViewAll: () => _navigate(const StudyProgressScreen())),
                            ),
                            const SizedBox(height: 32),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPurple.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _kWhite, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: _kPurple, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('NEXUS', style: TextStyle(
                  color: _kPurple, fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 2,
                )),
              ]),
              const SizedBox(height: 2),
              const Text('My Catalog', style: TextStyle(
                color: _kWhite, fontSize: 18, fontWeight: FontWeight.w800,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onViewAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              color: _kWhite.withOpacity(0.9),
              fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5,
            )),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Row(children: [
                Text('View All', style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600,
                )),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 11),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  QUIZ PREVIEW CARDS (in catalog)
// ═══════════════════════════════════════════════════════
class _QuizPreviewCards extends StatelessWidget {
  final VoidCallback onViewAll;
  const _QuizPreviewCards({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getQuizzes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(_kPurple);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('No quizzes yet', Icons.quiz_rounded, _kPurple);
        }
        final docs = snapshot.data!.docs.take(3).toList();
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final score = data['score'] ?? 0;
              final total = data['total'] ?? 1;
              final pct = data['percentage'] ?? 0;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuizDetailScreen(docId: docs[i].id, data: data),
                )),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kPurple.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _scoreColor(pct).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$pct%', style: TextStyle(
                            color: _scoreColor(pct), fontSize: 12, fontWeight: FontWeight.w800,
                          )),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 16),
                      ]),
                      const SizedBox(height: 8),
                      Text('$score / $total', style: const TextStyle(
                        color: _kWhite, fontSize: 18, fontWeight: FontWeight.w900,
                      )),
                      const SizedBox(height: 4),
                      Text(
                        date != null ? _formatDate(date) : 'Recent',
                        style: const TextStyle(color: _kMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _scoreColor(int pct) {
    if (pct >= 80) return _kGreen;
    if (pct >= 50) return const Color(0xFFF59E0B);
    return _kRed;
  }
}

// ═══════════════════════════════════════════════════════
//  VOICE NOTES PREVIEW CARDS (in catalog)
// ═══════════════════════════════════════════════════════
class _VoicePreviewCards extends StatelessWidget {
  final VoidCallback onViewAll;
  const _VoicePreviewCards({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getVoiceNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(_kGreen);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('No voice notes yet', Icons.mic_rounded, _kGreen);
        }
        final docs = snapshot.data!.docs.take(3).toList();
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final summary = data['summary'] ?? '';
              final duration = data['durationSeconds'] ?? 0;
              final wordCount = data['wordCount'] ?? 0;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VoiceNoteDetailScreen(docId: docs[i].id, data: data),
                )),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kGreen.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.mic_rounded, color: _kGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(_formatDuration(duration), style: const TextStyle(
                          color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700,
                        )),
                        const Spacer(),
                        Text('$wordCount w', style: const TextStyle(color: _kMuted, fontSize: 10)),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          summary.isNotEmpty ? summary : 'No summary',
                          style: const TextStyle(color: _kGrey, fontSize: 12, height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        date != null ? _formatDate(date) : 'Recent',
                        style: const TextStyle(color: _kMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SCANNED NOTES PREVIEW CARDS (in catalog)
// ═══════════════════════════════════════════════════════
class _ScannedPreviewCards extends StatelessWidget {
  final VoidCallback onViewAll;
  const _ScannedPreviewCards({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getScannedNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(_kIndigo);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('No scanned notes yet', Icons.document_scanner_rounded, _kIndigo);
        }
        final docs = snapshot.data!.docs.take(3).toList();
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final text = data['text'] ?? '';
              final wordCount = data['wordCount'] ?? 0;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ScannedNoteDetailScreen(docId: docs[i].id, data: data),
                )),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kIndigo.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.document_scanner_rounded, color: _kIndigo, size: 14),
                        const SizedBox(width: 4),
                        Text('$wordCount words', style: const TextStyle(
                          color: _kIndigo, fontSize: 11, fontWeight: FontWeight.w700,
                        )),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 14),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          text.isNotEmpty ? text : 'No text',
                          style: const TextStyle(color: _kGrey, fontSize: 12, height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        date != null ? _formatDate(date) : 'Recent',
                        style: const TextStyle(color: _kMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STUDY PROGRESS PREVIEW
// ═══════════════════════════════════════════════════════
class _StudyProgressPreview extends StatelessWidget {
  final VoidCallback onViewAll;
  const _StudyProgressPreview({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getTimerSessions(),
      builder: (context, snapshot) {
        int totalMinutes = 0;
        int totalSessions = 0;
        if (snapshot.hasData) {
          final now = DateTime.now();
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final year = data['year'] ?? 0;
            final month = data['month'] ?? 0;
            final day = data['day'] ?? 0;
            final date = DateTime(year, month, day);
            final diff = now.difference(date).inDays;
            if (diff <= 7) {
              totalMinutes += (data['totalMinutes'] as num?)?.toInt() ?? 0;
              totalSessions += (data['sessions'] as num?)?.toInt() ?? 0;
            }
          }
        }

        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        final goalMinutes = 300; // 5 hours weekly goal
        final progress = (totalMinutes / goalMinutes).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: onViewAll,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      hours > 0 ? '${hours}h ${mins}m' : '${mins}m',
                      style: const TextStyle(
                        color: _kWhite, fontSize: 28, fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('This week', style: TextStyle(color: _kMuted, fontSize: 12)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalSessions sessions',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: _kCardAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Text(
                    '${(progress * 100).toInt()}% of weekly goal',
                    style: const TextStyle(color: _kMuted, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    'Goal: 5h',
                    style: TextStyle(color: const Color(0xFFF59E0B).withOpacity(0.7), fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  QUIZ HISTORY SCREEN (full list)
// ═══════════════════════════════════════════════════════
class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Quiz History', Icons.quiz_rounded, _kPurple),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getQuizzes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _kPurple));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyFull('No quizzes yet!\nComplete a quiz to see results here.', Icons.quiz_rounded, _kPurple);
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final score = data['score'] ?? 0;
                      final total = data['total'] ?? 1;
                      final pct = data['percentage'] ?? 0;
                      final date = (data['createdAt'] as Timestamp?)?.toDate();
                      final color = pct >= 80 ? _kGreen : pct >= 50 ? const Color(0xFFF59E0B) : _kRed;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => QuizDetailScreen(docId: docs[i].id, data: data),
                        )),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text('$pct%', style: TextStyle(
                                  color: color, fontSize: 14, fontWeight: FontWeight.w900,
                                )),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$score out of $total correct', style: const TextStyle(
                                  color: _kWhite, fontSize: 16, fontWeight: FontWeight.w700,
                                )),
                                const SizedBox(height: 4),
                                Text(
                                  date != null ? _formatDate(date) : 'Recent',
                                  style: const TextStyle(color: _kMuted, fontSize: 12),
                                ),
                              ],
                            )),
                            Icon(Icons.chevron_right_rounded, color: color, size: 20),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  QUIZ DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class QuizDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const QuizDetailScreen({Key? key, required this.docId, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final score = data['score'] ?? 0;
    final total = data['total'] ?? 1;
    final pct = data['percentage'] ?? 0;
    final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final color = pct >= 80 ? _kGreen : pct >= 50 ? const Color(0xFFF59E0B) : _kRed;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Quiz Result', Icons.quiz_rounded, _kPurple),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Score card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20)],
                      ),
                      child: Column(children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.4), width: 2),
                          ),
                          child: Center(child: Text('$pct%', style: TextStyle(
                            color: color, fontSize: 24, fontWeight: FontWeight.w900,
                          ))),
                        ),
                        const SizedBox(height: 16),
                        Text('$score / $total Correct', style: const TextStyle(
                          color: _kWhite, fontSize: 22, fontWeight: FontWeight.w800,
                        )),
                        const SizedBox(height: 6),
                        Text(
                          date != null ? _formatDate(date) : 'Recent',
                          style: const TextStyle(color: _kMuted, fontSize: 13),
                        ),
                      ]),
                    ),

                    if (questions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('QUESTIONS', style: TextStyle(
                          color: _kWhite.withOpacity(0.4),
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                        )),
                      ),
                      const SizedBox(height: 12),
                      ...questions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final q = entry.value;
                        final isCorrect = q['isCorrect'] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCorrect ? _kGreen.withOpacity(0.3) : _kRed.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(
                                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isCorrect ? _kGreen : _kRed, size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text('Q${i + 1}', style: TextStyle(
                                  color: isCorrect ? _kGreen : _kRed,
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                )),
                              ]),
                              const SizedBox(height: 8),
                              Text(q['question'] ?? '', style: const TextStyle(
                                color: _kWhite, fontSize: 14, height: 1.4,
                              )),
                              if (q['correctAnswer'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Answer: ${q['correctAnswer']}',
                                  style: const TextStyle(color: _kGreen, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  VOICE NOTES HISTORY SCREEN
// ═══════════════════════════════════════════════════════
class VoiceNotesHistoryScreen extends StatelessWidget {
  const VoiceNotesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Voice Notes', Icons.mic_rounded, _kGreen),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getVoiceNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _kGreen));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyFull('No voice notes yet!\nRecord something to see it here.', Icons.mic_rounded, _kGreen);
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final summary = data['summary'] ?? '';
                      final duration = data['durationSeconds'] ?? 0;
                      final wordCount = data['wordCount'] ?? 0;
                      final date = (data['createdAt'] as Timestamp?)?.toDate();
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => VoiceNoteDetailScreen(docId: docs[i].id, data: data),
                        )),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kGreen.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _kGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.mic_rounded, color: _kGreen, size: 12),
                                    const SizedBox(width: 4),
                                    Text(_formatDuration(duration), style: const TextStyle(
                                      color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700,
                                    )),
                                  ]),
                                ),
                                const SizedBox(width: 8),
                                Text('$wordCount words', style: const TextStyle(
                                  color: _kMuted, fontSize: 11,
                                )),
                                const Spacer(),
                                Text(
                                  date != null ? _formatDate(date) : '',
                                  style: const TextStyle(color: _kMuted, fontSize: 11),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Text(
                                summary.isNotEmpty ? summary : 'No summary available',
                                style: const TextStyle(color: _kGrey, fontSize: 14, height: 1.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  VOICE NOTE DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class VoiceNoteDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const VoiceNoteDetailScreen({Key? key, required this.docId, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transcript = data['transcript'] ?? '';
    final summary = data['summary'] ?? '';
    final duration = data['durationSeconds'] ?? 0;
    final wordCount = data['wordCount'] ?? 0;
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Voice Note', Icons.mic_rounded, _kGreen),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kGreen.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        _statItem(Icons.schedule_rounded, _formatDuration(duration), 'Duration', _kGreen),
                        Container(width: 1, height: 40, color: _kDivider),
                        _statItem(Icons.text_fields_rounded, '$wordCount', 'Words', _kPurple),
                        Container(width: 1, height: 40, color: _kDivider),
                        _statItem(Icons.calendar_today_rounded,
                            date != null ? _formatDate(date) : 'N/A', 'Date', _kIndigo),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Summary
                    _buildDetailCard(
                      label: 'AI SUMMARY',
                      icon: Icons.auto_awesome_rounded,
                      content: summary.isNotEmpty ? summary : 'No summary',
                      color: _kPurple,
                    ),

                    const SizedBox(height: 16),

                    // Transcript
                    _buildDetailCard(
                      label: 'TRANSCRIPT',
                      icon: Icons.mic_rounded,
                      content: transcript.isNotEmpty ? transcript : 'No transcript',
                      color: _kGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(
        color: _kWhite, fontSize: 13, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
    ]));
  }

  Widget _buildDetailCard({
    required String label,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,
            )),
          ]),
        ),
        Divider(color: _kDivider, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(content, style: const TextStyle(
            color: _kWhite, fontSize: 15, height: 1.6,
          )),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SCANNED NOTES HISTORY SCREEN
// ═══════════════════════════════════════════════════════
class ScannedNotesHistoryScreen extends StatelessWidget {
  const ScannedNotesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Scanned Notes', Icons.document_scanner_rounded, _kIndigo),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getScannedNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _kIndigo));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyFull('No scanned notes yet!\nScan your notes to see them here.', Icons.document_scanner_rounded, _kIndigo);
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final wordCount = data['wordCount'] ?? 0;
                      final charCount = data['charCount'] ?? 0;
                      final date = (data['createdAt'] as Timestamp?)?.toDate();
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ScannedNoteDetailScreen(docId: docs[i].id, data: data),
                        )),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kIndigo.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _kIndigo.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$wordCount words', style: const TextStyle(
                                    color: _kIndigo, fontSize: 11, fontWeight: FontWeight.w700,
                                  )),
                                ),
                                const SizedBox(width: 8),
                                Text('$charCount chars', style: const TextStyle(
                                  color: _kMuted, fontSize: 11,
                                )),
                                const Spacer(),
                                Text(
                                  date != null ? _formatDate(date) : '',
                                  style: const TextStyle(color: _kMuted, fontSize: 11),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Text(
                                text.isNotEmpty ? text : 'No text extracted',
                                style: const TextStyle(color: _kGrey, fontSize: 14, height: 1.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SCANNED NOTE DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class ScannedNoteDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const ScannedNoteDetailScreen({Key? key, required this.docId, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = data['text'] ?? '';
    final wordCount = data['wordCount'] ?? 0;
    final charCount = data['charCount'] ?? 0;
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Scanned Note', Icons.document_scanner_rounded, _kIndigo),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kIndigo.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        _statItem(Icons.text_fields_rounded, '$wordCount', 'Words', _kIndigo),
                        Container(width: 1, height: 40, color: _kDivider),
                        _statItem(Icons.format_size_rounded, '$charCount', 'Chars', _kPurple),
                        Container(width: 1, height: 40, color: _kDivider),
                        _statItem(Icons.calendar_today_rounded,
                            date != null ? _formatDate(date) : 'N/A', 'Date', _kGreen),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kIndigo.withOpacity(0.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const Icon(Icons.document_scanner_rounded, color: _kIndigo, size: 14),
                            const SizedBox(width: 8),
                            const Text('EXTRACTED TEXT', style: TextStyle(
                              color: _kIndigo, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 1.2,
                            )),
                          ]),
                        ),
                        const Divider(color: _kDivider, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            text.isNotEmpty ? text : 'No text extracted',
                            style: const TextStyle(color: _kWhite, fontSize: 15, height: 1.7),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(
        color: _kWhite, fontSize: 13, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
    ]));
  }
}

// ═══════════════════════════════════════════════════════
//  STUDY PROGRESS SCREEN
// ═══════════════════════════════════════════════════════
class StudyProgressScreen extends StatelessWidget {
  const StudyProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, 'Study Progress', Icons.bar_chart_rounded, const Color(0xFFF59E0B)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getTimerSessions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final now = DateTime.now();

                  // Calculate this week stats
                  int weekMinutes = 0;
                  int weekSessions = 0;
                  int totalMinutes = 0;

                  // Build bar chart data (last 7 days)
                  final Map<String, int> last7Days = {};
                  for (int i = 6; i >= 0; i--) {
                    final day = now.subtract(Duration(days: i));
                    final key = '${day.year}_${day.month}_${day.day}';
                    last7Days[key] = 0;
                  }

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final year = data['year'] ?? 0;
                    final month = data['month'] ?? 0;
                    final day = data['day'] ?? 0;
                    final minutes = (data['totalMinutes'] as num?)?.toInt() ?? 0;
                    final sessions = (data['sessions'] as num?)?.toInt() ?? 0;
                    final key = '${year}_${month}_${day}';
                    final date = DateTime(year, month, day);
                    final diff = now.difference(date).inDays;

                    totalMinutes += minutes;
                    if (diff <= 7) {
                      weekMinutes += minutes;
                      weekSessions += sessions;
                    }
                    if (last7Days.containsKey(key)) {
                      last7Days[key] = minutes;
                    }
                  }

                  final maxMinutes = last7Days.values.isEmpty ? 1 :
                  last7Days.values.reduce((a, b) => a > b ? a : b).clamp(1, 999);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards
                        Row(children: [
                          _summaryCard(
                            '${weekMinutes ~/ 60}h ${weekMinutes % 60}m',
                            'This Week',
                            Icons.calendar_today_rounded,
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            '$weekSessions',
                            'Sessions',
                            Icons.timer_rounded,
                            _kPurple,
                          ),
                        ]),

                        const SizedBox(height: 12),

                        Row(children: [
                          _summaryCard(
                            '${totalMinutes ~/ 60}h',
                            'Total Hours',
                            Icons.history_rounded,
                            _kGreen,
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            '${((weekMinutes / 300) * 100).toInt().clamp(0, 100)}%',
                            'Weekly Goal',
                            Icons.flag_rounded,
                            _kIndigo,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Bar chart title
                        Text('LAST 7 DAYS', style: TextStyle(
                          color: _kWhite.withOpacity(0.4),
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                        )),
                        const SizedBox(height: 16),

                        // Bar chart
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 140,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: last7Days.entries.map((entry) {
                                    final parts = entry.key.split('_');
                                    final day = DateTime(
                                      int.parse(parts[0]),
                                      int.parse(parts[1]),
                                      int.parse(parts[2]),
                                    );
                                    final mins = entry.value;
                                    final heightRatio = mins / maxMinutes;
                                    final isToday = day.day == now.day &&
                                        day.month == now.month &&
                                        day.year == now.year;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (mins > 0)
                                          Text('${mins}m', style: TextStyle(
                                            color: isToday ? const Color(0xFFF59E0B) : _kMuted,
                                            fontSize: 9, fontWeight: FontWeight.w600,
                                          )),
                                        const SizedBox(height: 4),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 600),
                                          width: 28,
                                          height: (heightRatio * 100).clamp(4.0, 100.0),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? const Color(0xFFF59E0B)
                                                : mins > 0
                                                ? const Color(0xFFF59E0B).withOpacity(0.4)
                                                : _kCardAlt,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: last7Days.keys.map((key) {
                                  final parts = key.split('_');
                                  final day = DateTime(
                                    int.parse(parts[0]),
                                    int.parse(parts[1]),
                                    int.parse(parts[2]),
                                  );
                                  const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                                  final isToday = day.day == now.day &&
                                      day.month == now.month &&
                                      day.year == now.year;
                                  return SizedBox(
                                    width: 28,
                                    child: Text(
                                      isToday ? 'Now' : days[day.weekday - 1],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isToday ? const Color(0xFFF59E0B) : _kMuted,
                                        fontSize: 10,
                                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Weekly goal progress
                        Text('WEEKLY GOAL', style: TextStyle(
                          color: _kWhite.withOpacity(0.4),
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                        )),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(
                                  '${weekMinutes ~/ 60}h ${weekMinutes % 60}m / 5h',
                                  style: const TextStyle(
                                    color: _kWhite, fontSize: 16, fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${((weekMinutes / 300) * 100).toInt().clamp(0, 100)}%',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (weekMinutes / 300).clamp(0.0, 1.0),
                                  backgroundColor: _kCardAlt,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(
                color: _kWhite, fontSize: 15, fontWeight: FontWeight.w800,
              )),
              Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
            ],
          )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════

Widget _buildHeader(BuildContext context, String title, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: _kDivider)),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: _kWhite, size: 20),
        ),
      ),
      const SizedBox(width: 14),
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        color: _kWhite, fontSize: 18, fontWeight: FontWeight.w800,
      )),
    ]),
  );
}

Widget _buildLoading(Color color) {
  return SizedBox(
    height: 120,
    child: Center(child: CircularProgressIndicator(color: color, strokeWidth: 2)),
  );
}

Widget _buildEmpty(String msg, IconData icon, Color color) {
  return Container(
    height: 100,
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color.withOpacity(0.3), size: 24),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(color: _kMuted, fontSize: 12)),
      ]),
    ),
  );
}

Widget _buildEmptyFull(String msg, IconData icon, Color color) {
  return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color.withOpacity(0.3), size: 60),
      const SizedBox(height: 16),
      Text(msg, textAlign: TextAlign.center, style: const TextStyle(
        color: _kMuted, fontSize: 15, height: 1.6,
      )),
    ]),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  return '${date.day}/${date.month}/${date.year}';
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s > 0 ? '${m}m ${s}s' : '${m}m';
}