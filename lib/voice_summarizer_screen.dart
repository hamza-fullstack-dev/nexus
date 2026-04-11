import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math';
import 'voice_service.dart';
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
const Color kRed        = Color(0xFFEF4444);

class VoiceSummarizerScreen extends StatefulWidget {
  const VoiceSummarizerScreen({Key? key}) : super(key: key);

  @override
  State<VoiceSummarizerScreen> createState() => _VoiceSummarizerScreenState();
}

class _VoiceSummarizerScreenState extends State<VoiceSummarizerScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasResult = false;
  String _recordingPath = '';
  int _recordingSeconds = 0;
  String _transcript = '';
  String _summary = '';
  String _processingStep = '';

  // ADDED: save state
  bool _isSaving = false;
  bool _isSaved = false;

  // ── flutter_sound Recorder ─────────────────
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  Timer? _recordingTimer;

  // ── Animations ─────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final List<double> _waveBars = List.generate(30, (i) => 0.1);
  final Random _random = Random();
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _pulseController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ── Recording logic ────────────────────────
  Future<void> _startRecording() async {
    if (!_recorderReady) {
      _showSnackbar('Microphone not ready. Check permissions.', isError: true);
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/nexus_voice_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacMP4,
    );

    HapticFeedback.mediumImpact();
    _pulseController.repeat(reverse: true);

    // Animate wave bars
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        for (int i = 0; i < _waveBars.length; i++) {
          _waveBars[i] = 0.1 + _random.nextDouble() * 0.9;
        }
      });
    });

    // Timer counter
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _hasResult = false;
      _transcript = '';
      _summary = '';
      _isSaved = false; // ADDED: reset save state on new recording
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    for (int i = 0; i < _waveBars.length; i++) {
      _waveBars[i] = 0.1;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isRecording = false);

    if (_recordingSeconds < 2) {
      _showSnackbar('Recording too short. Hold for at least 2 seconds.', isError: true);
      return;
    }

    await _processRecording();
  }

  Future<void> _processRecording() async {
    setState(() {
      _isProcessing = true;
      _processingStep = 'Transcribing audio...';
    });

    try {
      // Step 1: Transcribe with Whisper
      final transcript = await VoiceService.transcribeAudio(_recordingPath);
      setState(() {
        _transcript = transcript;
        _processingStep = 'Summarizing with AI...';
      });

      // Step 2: Summarize with Groq
      final summary = await VoiceService.summarizeText(transcript);

      setState(() {
        _summary = summary;
        _isProcessing = false;
        _hasResult = true;
      });

      // ADDED: auto-save after processing
      await _saveToFirestore();

    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackbar('Error: ${e.toString()}', isError: true);
      debugPrint('NEXUS VOICE ERROR: $e');
    }
  }

  // ADDED: save voice note to Firestore
  Future<void> _saveToFirestore() async {
    if (_isSaved) return;
    // ADD THESE 2 LINES:
    print('USER: ${FirebaseAuth.instance.currentUser?.uid}');
    print('TRANSCRIPT EMPTY: ${_transcript.isEmpty}');
    setState(() => _isSaving = true);
    try {
      await FirestoreService.saveVoiceNote(
        transcript: _transcript,
        summary: _summary,
        durationSeconds: _recordingSeconds,
      );
      setState(() { _isSaving = false; _isSaved = true; });
      _showSnackbar('Voice note saved to history!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackbar('Could not save note.', isError: true);
    }
  }

  void _reset() {
    setState(() {
      _hasResult = false;
      _transcript = '';
      _summary = '';
      _recordingSeconds = 0;
      _isSaved = false; // ADDED
    });
  }

  String get _formattedTime {
    final m = _recordingSeconds ~/ 60;
    final s = _recordingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? kRed : kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: kWhite))),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isProcessing
                  ? _buildProcessingState()
                  : _hasResult
                  ? _buildResultView()
                  : _buildRecorderView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
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
                const Text('NEXUS VOICE',
                    style: TextStyle(color: kPurple, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 2),
              const Text('Voice Summarizer',
                  style: TextStyle(color: kWhite, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          if (_hasResult)
            GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kPurpleSub,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPurple.withOpacity(0.4)),
                ),
                child: Row(children: const [
                  Icon(Icons.mic_rounded, color: kPurple, size: 16),
                  SizedBox(width: 6),
                  Text('New', style: TextStyle(color: kPurple, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  RECORDER VIEW
  // ─────────────────────────────────────────────
  Widget _buildRecorderView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Quick tip card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPurpleSub,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPurple.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: kPurple, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Tip',
                        style: TextStyle(color: kPurple, fontSize: 13, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text(
                      'Speak clearly for best results. AI will transcribe and summarize your voice note automatically.',
                      style: TextStyle(color: kGrey, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 40),

          // ── Waveform display ──
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_waveBars.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: _isRecording ? _waveBars[i] * 70 : 4,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? kPurple.withOpacity(0.4 + _waveBars[i] * 0.6)
                        : kCardAlt,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 32),

          // ── Timer display ──
          Text(
            _isRecording ? _formattedTime : '00:00',
            style: TextStyle(
              color: _isRecording ? kPurple : kMuted,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isRecording ? 'Recording...' : 'Tap to start recording',
            style: TextStyle(color: _isRecording ? kGrey : kMuted, fontSize: 14),
          ),

          const Spacer(),

          // ── Record button ──
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _isRecording ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? kRed : kPurple,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? kRed : kPurple).withOpacity(0.4),
                      blurRadius: 30, spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: kWhite, size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _isRecording ? 'Tap to stop' : 'Tap mic to record',
            style: const TextStyle(color: kMuted, fontSize: 13),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PROCESSING STATE
  // ─────────────────────────────────────────────
  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: kPurpleSub,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: kPurple.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Stack(alignment: Alignment.center, children: [
              const SizedBox(
                width: 65, height: 65,
                child: CircularProgressIndicator(color: kPurple, strokeWidth: 3),
              ),
              const Icon(Icons.auto_awesome_rounded, color: kPurple, size: 28),
            ]),
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: kPurple, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('NEXUS AI',
                style: TextStyle(color: kPurple, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          const Text('Processing Voice Note',
              style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_processingStep, style: const TextStyle(color: kGrey, fontSize: 14)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  RESULT VIEW
  // ─────────────────────────────────────────────
  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDivider),
            ),
            child: Row(children: [
              _statItem(
                _recordingSeconds >= 60
                    ? '${_recordingSeconds ~/ 60}m ${_recordingSeconds % 60}s'
                    : '${_recordingSeconds}s',
                'Duration', Icons.schedule_rounded, kPurple,
              ),
              Container(width: 1, height: 40, color: kDivider),
              _statItem(
                '${_transcript.split(' ').where((w) => w.isNotEmpty).length}',
                'Words', Icons.text_fields_rounded, kGreen,
              ),
              Container(width: 1, height: 40, color: kDivider),
              _statItem(
                '${_summary.split(' ').where((w) => w.isNotEmpty).length}',
                'Summary', Icons.summarize_rounded, kPurple,
              ),
            ]),
          ),

          const SizedBox(height: 20),

          _buildResultCard(
            label: 'AI SUMMARY',
            icon: Icons.auto_awesome_rounded,
            content: _summary,
            iconColor: kPurple,
            borderColor: kPurple,
          ),

          const SizedBox(height: 16),

          _buildResultCard(
            label: 'TRANSCRIPT',
            icon: Icons.mic_rounded,
            content: _transcript,
            iconColor: kGreen,
            borderColor: kGreen,
          ),

          const SizedBox(height: 20),

          // ADDED: Save button
          GestureDetector(
            onTap: _isSaved || _isSaving ? null : _saveToFirestore,
            child: Container(
              width: double.infinity,
              height: 52,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _isSaved ? kGreen.withOpacity(0.15) : kPurpleSub,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isSaved ? kGreen.withOpacity(0.4) : kPurple.withOpacity(0.4),
                ),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_isSaving)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: kPurple, strokeWidth: 2))
                else
                  Icon(_isSaved ? Icons.check_circle_rounded : Icons.save_rounded,
                      color: _isSaved ? kGreen : kPurple, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isSaving ? 'Saving...' : _isSaved ? 'Saved to History ✓' : 'Save Note',
                  style: TextStyle(
                    color: _isSaved ? kGreen : kPurple,
                    fontWeight: FontWeight.w700, fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),

          // ── Action buttons (UNCHANGED) ──
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _summary));
                  _showSnackbar('Summary copied!');
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: kCardAlt, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.copy_rounded, color: kGrey, size: 18),
                    SizedBox(width: 8),
                    Text('Copy Summary',
                        style: TextStyle(color: kGrey, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _transcript));
                  _showSnackbar('Transcript copied!');
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPurple, kPurpleDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.copy_rounded, color: kWhite, size: 18),
                    SizedBox(width: 8),
                    Text('Copy Transcript',
                        style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String label,
    required IconData icon,
    required String content,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                  color: iconColor, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ]),
          ),
          Divider(color: kDivider, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content,
                style: const TextStyle(color: kWhite, fontSize: 15, height: 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(val, style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
    ]));
  }
}