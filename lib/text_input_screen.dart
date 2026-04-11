import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_service.dart';
import 'quiz_screen.dart';

// ==============================================================================
// TEXT INPUT SCREEN - Direct Text Paste for Quiz Generation
// ==============================================================================
// User can type or paste text directly without taking photo
// ==============================================================================

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({Key? key}) : super(key: key);

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Paste from clipboard
  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 20),
              SizedBox(width: 12),
              Text('Text pasted!'),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Text('No text in clipboard'),
            ],
          ),
        ),
      );
    }
  }

  // Generate quiz
  Future<void> _generateQuiz() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 20),
              SizedBox(width: 12),
              Text('Please enter some text first'),
            ],
          ),
        ),
      );
      return;
    }

    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Text is too short. Add at least 50 characters.'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final questions = await QuizService.generateQuiz(
        text: text,
        numberOfQuestions: 10,
      );

      setState(() => _isGenerating = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            questions: questions,
            noteTitle: 'Custom Text Quiz',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isGenerating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to generate quiz')),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _textController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = _textController.text.length;

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 20),
                    _buildStatsCard(wordCount, charCount),
                    SizedBox(height: 20),
                    _buildTextInput(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
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
                      'NEXUS',
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
                  'Paste Text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6).withOpacity(0.1), Color(0xFF7C3AED).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline, color: Color(0xFF8B5CF6), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Paste at least 50 characters for best quiz results',
                  style: TextStyle(
                    color: Colors.white70,
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

  Widget _buildStatsCard(int words, int chars) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1F1F1F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.text_fields, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(height: 8),
                Text(
                  '$words',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Words',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Color(0xFF1F1F1F)),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.format_size, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(height: 8),
                Text(
                  '$chars',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Characters',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Color(0xFF1F1F1F)),
          Expanded(
            child: Column(
              children: [
                Icon(
                  chars >= 50 ? Icons.check_circle : Icons.hourglass_empty,
                  color: chars >= 50 ? Colors.green : Colors.orange,
                  size: 20,
                ),
                SizedBox(height: 8),
                Text(
                  chars >= 50 ? 'Ready' : 'Too Short',
                  style: TextStyle(
                    color: chars >= 50 ? Colors.green : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1F1F1F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
            ),
            child: Row(
              children: [
                Icon(Icons.article, color: Colors.white38, size: 16),
                SizedBox(width: 8),
                Text(
                  'Your Text',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: _pasteFromClipboard,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.content_paste, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Paste',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: 300),
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: _textController,
              maxLines: null,
              onChanged: (value) => setState(() {}),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Type or paste your study notes here...',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
        ),
        child: GestureDetector(
          onTap: _isGenerating ? null : _generateQuiz,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _isGenerating
                  ? null
                  : LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              color: _isGenerating ? Color(0xFF1A1A1A) : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isGenerating
                  ? null
                  : [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _isGenerating
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white38,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Generating Quiz...',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Generate Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}