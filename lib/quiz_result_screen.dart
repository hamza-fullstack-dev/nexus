import 'package:flutter/material.dart';
import 'quiz_service.dart';
import 'quiz_screen.dart';
import 'firestore_service.dart'; // ✅ ADDED: Firebase save

// ==============================================================================
// QUIZ RESULT SCREEN - Show Score & Review Answers + Save to Firebase
// ==============================================================================

class QuizResultScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Map<int, String> userAnswers;
  final String noteTitle;

  const QuizResultScreen({
    Key? key,
    required this.questions,
    required this.userAnswers,
    this.noteTitle = 'Quiz',
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // ✅ ADDED: Auto-save quiz result when screen loads
    _saveQuizResult();
  }

  int get _correctCount {
    int count = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final userAnswer = widget.userAnswers[i];
      if (userAnswer != null && widget.questions[i].isCorrect(userAnswer)) {
        count++;
      }
    }
    return count;
  }

  double get _percentage => (_correctCount / widget.questions.length) * 100;

  // ✅ ADDED: Save quiz result to Firebase
  Future<void> _saveQuizResult() async {
    if (_isSaved) return;

    try {
      // Convert questions to Map format for Firebase
      final questionsData = widget.questions.map((q) {
        return {
          'question': q.question,
          'options': q.options,
          'correctAnswer': q.correctAnswer,
          'explanation': q.explanation,
        };
      }).toList();

      await FirestoreService.saveQuiz(
        title: widget.noteTitle,
        questions: questionsData,
        score: _correctCount,
        total: widget.questions.length,
      );

      setState(() => _isSaved = true);
      debugPrint('✅ Quiz saved to Firebase!');
    } catch (e) {
      debugPrint('❌ Failed to save quiz: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScoreCard(),
                    _buildAnswerReview(),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'QUIZ RESULTS',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  widget.noteTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ✅ ADDED: Save indicator
          if (_isSaved)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green[700]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[700]!.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, color: Colors.green[400], size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final isPass = _percentage >= 60;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPass
              ? [Color(0xFF10B981), Color(0xFF059669)]
              : [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPass ? Color(0xFF10B981) : Color(0xFFEF4444)).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPass ? Icons.celebration : Icons.emoji_events_outlined,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(height: 20),
          Text(
            isPass ? 'Great Job!' : 'Keep Practicing!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '$_correctCount / ${widget.questions.length}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_percentage.toStringAsFixed(0)}% Score',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReview() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Review Answers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...List.generate(widget.questions.length, (index) {
            return _buildAnswerCard(index);
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(int index) {
    final question = widget.questions[index];
    final userAnswer = widget.userAnswers[index];
    final isCorrect = userAnswer != null && question.isCorrect(userAnswer);
    final options = ['A', 'B', 'C', 'D'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: TextStyle(
                        color: isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Text(
                'Question ${index + 1}',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            question.question,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(4, (optIndex) {
            final option = options[optIndex];
            final isUserAnswer = userAnswer == option;
            final isCorrectAnswer = question.correctAnswer == option;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrectAnswer
                    ? Color(0xFF10B981).withOpacity(0.1)
                    : (isUserAnswer && !isCorrect
                    ? Color(0xFFEF4444).withOpacity(0.1)
                    : Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrectAnswer
                      ? Color(0xFF10B981)
                      : (isUserAnswer && !isCorrect
                      ? Color(0xFFEF4444)
                      : Colors.transparent),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCorrectAnswer
                          ? Color(0xFF10B981)
                          : (isUserAnswer && !isCorrect
                          ? Color(0xFFEF4444)
                          : Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.options[optIndex],
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCorrectAnswer)
                    Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                  if (isUserAnswer && !isCorrect)
                    Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                ],
              ),
            );
          }),
          if (!isCorrect) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Color(0xFF8B5CF6), size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Back to Notes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      questions: widget.questions,
                      noteTitle: widget.noteTitle,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Retry Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}