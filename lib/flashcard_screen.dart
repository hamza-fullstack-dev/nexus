import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flashcard_service.dart';

// ─────────────────────────────────────────────
//  NEXUS COLOR PALETTE (matches your app exactly)
// ─────────────────────────────────────────────
const Color kBackground   = Color(0xFF0D0D0D);
const Color kCard         = Color(0xFF1A1A1A);
const Color kCardAlt      = Color(0xFF1E1E1E);
const Color kPurplePrimary= Color(0xFF7C3AED);
const Color kPurpleLight  = Color(0xFF6366F1);
const Color kPurpleSubtle = Color(0xFF2D1B69);
const Color kTextPrimary  = Color(0xFFFFFFFF);
const Color kTextSecondary= Color(0xFF9CA3AF);
const Color kTextMuted    = Color(0xFF6B7280);
const Color kDivider      = Color(0xFF2D2D2D);

class FlashcardScreen extends StatefulWidget {
  final String extractedText;

  const FlashcardScreen({Key? key, required this.extractedText}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────
  List<Flashcard> _flashcards = [];
  bool _isLoading = false;
  bool _isGenerated = false;
  int _currentIndex = 0;
  bool _isFlipped = false;
  String? _errorMessage;

  // ── Animation controllers ──────────────────
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────

  Future<void> _generateFlashcards() async {
    if (widget.extractedText.trim().length < 50) {
      setState(() => _errorMessage = 'Text too short. Need at least 50 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cards = await FlashcardService.generateFlashcards(
        widget.extractedText,
        count: 10,
      );
      setState(() {
        _flashcards = cards;
        _isGenerated = true;
        _currentIndex = 0;
        _isFlipped = false;
        _isLoading = false;
      });
      _slideController.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate flashcards. Check your API key.';
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      HapticFeedback.selectionClick();
      _slideController.forward(from: 0);
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reverse();
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reverse();
      });
    }
  }

  void _reset() {
    setState(() {
      _isGenerated = false;
      _flashcards = [];
      _currentIndex = 0;
      _isFlipped = false;
    });
    _flipController.reverse();
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _isGenerated
                  ? _buildFlashcardView()
                  : _buildInitialState(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER  (matches your app: NEXUS label + title)
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(bottom: BorderSide(color: kDivider, width: 1)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: _isGenerated ? _reset : () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isGenerated ? Icons.refresh_rounded : Icons.arrow_back_rounded,
                color: kTextPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kPurplePrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NEXUS FLASHCARDS',
                    style: TextStyle(
                      color: kPurplePrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Your Notes Flashcards',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Card counter (shown only when generated)
          if (_isGenerated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${_flashcards.length}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  INITIAL STATE  (before generation)
  // ─────────────────────────────────────────────
  Widget _buildInitialState() {
    final wordCount = widget.extractedText.trim().split(RegExp(r'\s+')).length;
    final charCount = widget.extractedText.length;
    final isReady = charCount >= 50;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Stats card (matches your Words / Characters / Lines style) ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildStatItem(wordCount.toString(), 'Words', Icons.text_fields_rounded, kPurplePrimary),
                _buildDividerLine(),
                _buildStatItem(charCount.toString(), 'Characters', Icons.text_snippet_rounded, kPurplePrimary),
                _buildDividerLine(),
                _buildStatItem(
                  isReady ? 'Ready' : 'Short',
                  'Status',
                  isReady ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                  isReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick Tip card (matches your purple tip card style) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPurpleSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPurplePrimary.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kPurplePrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: kPurplePrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quick Tip',
                        style: TextStyle(
                          color: kPurplePrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'AI will create 10 smart flashcards from your notes. Tap each card to reveal the answer!',
                        style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Preview of extracted text ──
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.article_outlined, color: kTextMuted, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Notes',
                        style: TextStyle(color: kTextMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: kDivider, height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.extractedText.isEmpty
                            ? 'No text provided...'
                            : widget.extractedText,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1010),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Generate Button (matches your purple CTA style) ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isReady ? _generateFlashcards : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady ? kPurplePrimary : kCard,
                foregroundColor: kTextPrimary,
                disabledBackgroundColor: kCard,
                disabledForegroundColor: kTextMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isReady ? 'Generate Flashcards' : 'Text Too Short',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LOADING STATE
  // ─────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing purple spinner
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kPurpleSubtle,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPurplePrimary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: kPurplePrimary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Generating Flashcards...',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'AI is analyzing your notes',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FLASHCARD VIEW (the main card experience)
  // ─────────────────────────────────────────────
  Widget _buildFlashcardView() {
    return Column(
      children: [
        // ── Progress bar (matches your quiz style) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of ${_flashcards.length}',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  Text(
                    '${((_currentIndex + 1) / _flashcards.length * 100).toInt()}% Complete',
                    style: const TextStyle(color: kPurplePrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _flashcards.length,
                  backgroundColor: kCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(kPurplePrimary),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        // ── Category badge ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kPurpleSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _flashcards[_currentIndex].category,
                  style: const TextStyle(
                    color: kPurplePrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tap card to flip',
                style: TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── THE FLIP CARD ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * 3.14159;
                    final isFrontVisible = angle < 1.5708;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isFrontVisible
                          ? _buildCardFace(
                        label: 'QUESTION',
                        content: _flashcards[_currentIndex].front,
                        icon: Icons.help_outline_rounded,
                        isFlipped: false,
                      )
                          : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _buildCardFace(
                          label: 'ANSWER',
                          content: _flashcards[_currentIndex].back,
                          icon: Icons.check_circle_outline_rounded,
                          isFlipped: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Navigation buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Previous
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _currentIndex > 0 ? _previousCard : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCard,
                      disabledBackgroundColor: kCard,
                      foregroundColor: kTextPrimary,
                      disabledForegroundColor: kTextMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back_ios_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Prev', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Flip (center shortcut)
              GestureDetector(
                onTap: _flipCard,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: kPurpleSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kPurplePrimary.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.flip_rounded, color: kPurplePrimary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Next / Finish
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _currentIndex < _flashcards.length - 1
                        ? _nextCard
                        : () => _showCompletionDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex < _flashcards.length - 1
                          ? kPurplePrimary
                          : const Color(0xFF10B981),
                      foregroundColor: kTextPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex < _flashcards.length - 1 ? 'Next' : 'Done',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentIndex < _flashcards.length - 1
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.check_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Dot indicators ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _flashcards.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentIndex ? kPurplePrimary : kCard,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  CARD FACE (front & back)
  // ─────────────────────────────────────────────
  Widget _buildCardFace({
    required String label,
    required String content,
    required IconData icon,
    required bool isFlipped,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFlipped
              ? const Color(0xFF10B981).withOpacity(0.4)
              : kPurplePrimary.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isFlipped ? const Color(0xFF10B981) : kPurplePrimary).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Icon(
                  icon,
                  color: isFlipped ? const Color(0xFF10B981) : kPurplePrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isFlipped ? const Color(0xFF10B981) : kPurplePrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.touch_app_rounded, color: kTextMuted, size: 16),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: kDivider, height: 1),
            const SizedBox(height: 24),

            // Main content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: isFlipped ? 16 : 20,
                      fontWeight: isFlipped ? FontWeight.normal : FontWeight.bold,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bottom hint
            Center(
              child: Text(
                isFlipped ? 'Swipe → for next card' : 'Tap to reveal answer',
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  COMPLETION DIALOG
  // ─────────────────────────────────────────────
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: kPurpleSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: kPurplePrimary, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Flashcards Complete!',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You\'ve reviewed all ${_flashcards.length} flashcards.',
                style: const TextStyle(color: kTextSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _reset();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCardAlt,
                          foregroundColor: kTextPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Back to Notes'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 0;
                            _isFlipped = false;
                            _flipController.reverse();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurplePrimary,
                          foregroundColor: kTextPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Restart',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ──────────────────────────

  Widget _buildStatItem(String value, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDividerLine() {
    return Container(
      width: 1,
      height: 40,
      color: kDivider,
    );
  }
}