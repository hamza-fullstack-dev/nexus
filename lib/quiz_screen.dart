import 'package:flutter/material.dart';
import 'quiz_service.dart';
import 'quiz_result_screen.dart';
import 'firestore_service.dart';

// ==============================================================================
// QUIZ SCREEN - Take AI-Generated Quiz (NEXUS Styled!)
// ==============================================================================

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String noteTitle;

  const QuizScreen({
    Key? key,
    required this.questions,
    this.noteTitle = 'Quiz',
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _userAnswers = {};  // Stores user's answers

  QuizQuestion get _currentQuestion => widget.questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == widget.questions.length - 1;

  void _selectAnswer(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  // ==============================================================================
  // ADDED: Calculate score and save quiz to Firestore, then navigate to results
  // ==============================================================================
  Future<void> _finishQuiz() async {
    int score = 0;
    final questionsData = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final userAnswer = _userAnswers[i] ?? '';
      final isCorrect = userAnswer == q.correctAnswer;
      if (isCorrect) score++;

      questionsData.add({
        'question': q.question,
        'options': q.options,
        'correctAnswer': q.correctAnswer,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
      });
    }

    // Save to Firestore
    try {
      await FirestoreService.saveQuiz(
        title: widget.noteTitle,
        questions: questionsData,
        score: score,
        total: widget.questions.length,
      );
    } catch (e) {
      debugPrint('Could not save quiz: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            questions: widget.questions,
            userAnswers: _userAnswers,
            noteTitle: widget.noteTitle,
          ),
        ),
      );
    }
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      // Quiz complete — save and show results
      _finishQuiz();
    } else {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(),
                    SizedBox(height: 30),
                    _buildOptionsGrid(),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // HEADER
  // ==============================================================================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F1F1F)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white70, size: 18),
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
                      'NEXUS QUIZ',
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
        ],
      ),
    );
  }

  // ==============================================================================
  // PROGRESS BAR
  // ==============================================================================
  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_userAnswers.length / widget.questions.length * 100).toInt()}% Complete',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Color(0xFF1F1F1F),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // QUESTION CARD
  // ==============================================================================
  Widget _buildQuestionCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1F1F1F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Multiple Choice',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _currentQuestion.question,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // OPTIONS GRID
  // ==============================================================================
  Widget _buildOptionsGrid() {
    final options = ['A', 'B', 'C', 'D'];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];

    return Column(
      children: List.generate(4, (index) {
        final option = options[index];
        final isSelected = selectedAnswer == option;

        return GestureDetector(
          onTap: () => _selectAnswer(option),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF8B5CF6).withOpacity(0.1) : Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Color(0xFF8B5CF6) : Color(0xFF1F1F1F),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF8B5CF6) : Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentQuestion.options[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==============================================================================
  // NAVIGATION BUTTONS
  // ==============================================================================
  Widget _buildNavigationButtons() {
    final hasAnswer = _userAnswers.containsKey(_currentQuestionIndex);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousQuestion,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Previous',
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
          if (_currentQuestionIndex > 0) SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: hasAnswer ? _nextQuestion : null,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: hasAnswer
                      ? LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  )
                      : null,
                  color: hasAnswer ? null : Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasAnswer
                      ? [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _isLastQuestion ? 'Finish Quiz' : 'Next Question',
                    style: TextStyle(
                      color: hasAnswer ? Colors.white : Colors.white38,
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