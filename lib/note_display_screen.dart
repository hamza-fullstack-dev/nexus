import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'quiz_service.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';
import 'firestore_service.dart'; // ✅ ADDED: Firebase save

class NoteDisplayScreen extends StatefulWidget {
  final String extractedText;
  final String imagePath;

  const NoteDisplayScreen({
    Key? key,
    required this.extractedText,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<NoteDisplayScreen> createState() => _NoteDisplayScreenState();
}

class _NoteDisplayScreenState extends State<NoteDisplayScreen> {
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _showOriginal = false;

  // ✅ ADDED: Save state tracking
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.extractedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1F1F1F),
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 20),
            SizedBox(width: 12),
            Text('Copied to clipboard'),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Now saves to Firebase!
  Future<void> _saveNote() async {
    if (_isSaved) {
      // Already saved, just go back
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to Firebase
      await FirestoreService.saveScannedNote(
        text: _textController.text,
        imageUrl: widget.imagePath, // You can upload to Cloudinary later
      );

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[400], size: 20),
              SizedBox(width: 12),
              Text('Note saved to Firebase!'),
            ],
          ),
        ),
      );

      // Wait a bit then go back
      await Future.delayed(Duration(milliseconds: 800));
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 20),
              SizedBox(width: 12),
              Text('Failed to save note'),
            ],
          ),
        ),
      );
    }
  }

  // ✅ NEW: Navigate to Flashcard Screen
  void _goToFlashcards() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          extractedText: _textController.text,
        ),
      ),
    );
  }

  Future<void> _generateQuiz() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DefaultTextStyle(
        style: TextStyle(decoration: TextDecoration.none),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(0xFF8B5CF6).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6).withOpacity(0.2),
                        Color(0xFF7C3AED).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                          strokeWidth: 3,
                        ),
                      ),
                      Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 32),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'NEXUS AI',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Generating Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Creating intelligent questions...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final questions = await QuizService.generateQuiz(
        text: _textController.text,
        numberOfQuestions: 10,
      );

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            questions: questions,
            noteTitle: 'Your Notes Quiz',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1F1F),
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to generate quiz. Please try again.')),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  if (_showOriginal) _buildOriginalImage(),
                  _buildTextEditor(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F), width: 1)),
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
                    'Extracted Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showOriginal = !_showOriginal),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showOriginal ? Color(0xFF8B5CF6) : Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
    );
  }

  Widget _buildStatsCard() {
    final wordCount = _textController.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final charCount = _textController.text.length;
    final lineCount = _textController.text.split('\n').length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1F1F1F)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStat('$wordCount', 'Words', Icons.text_fields)),
          Container(width: 1, height: 40, color: Color(0xFF1F1F1F)),
          Expanded(child: _buildStat('$charCount', 'Characters', Icons.format_size)),
          Container(width: 1, height: 40, color: Color(0xFF1F1F1F)),
          Expanded(child: _buildStat('$lineCount', 'Lines', Icons.subject)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF8B5CF6), size: 20),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalImage() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Original Image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditing ? Color(0xFF8B5CF6) : Color(0xFF1F1F1F),
          width: _isEditing ? 2 : 1,
        ),
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
                Icon(
                  _isEditing ? Icons.edit : Icons.article,
                  color: _isEditing ? Color(0xFF8B5CF6) : Colors.white38,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  _isEditing ? 'Edit Mode' : 'Extracted Text',
                  style: TextStyle(
                    color: _isEditing ? Color(0xFF8B5CF6) : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _isEditing = !_isEditing);
                    if (_isEditing) HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEditing ? Color(0xFF8B5CF6) : Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isEditing ? 'Done' : 'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
              enabled: _isEditing,
              maxLines: null,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'No text extracted',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
              ),
              cursorColor: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED BOTTOM BAR — Copy | Quiz | Flashcards | Save (with Firebase!)
  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
        ),
        child: Row(
          children: [
            // Copy
            Expanded(
              child: GestureDetector(
                onTap: _copyToClipboard,
                child: _buildBarButton(Icons.copy, 'Copy', false),
              ),
            ),

            SizedBox(width: 10),

            // Quiz
            Expanded(
              child: GestureDetector(
                onTap: _generateQuiz,
                child: _buildBarButton(Icons.quiz, 'Quiz', false),
              ),
            ),

            SizedBox(width: 10),

            // Flashcards button
            Expanded(
              child: GestureDetector(
                onTap: _goToFlashcards,
                child: _buildBarButton(Icons.style_rounded, 'Cards', false),
              ),
            ),

            SizedBox(width: 10),

            // ✅ UPDATED: Save Note (Firebase save with loading state!)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _isSaving ? null : _saveNote,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isSaved
                        ? null
                        : LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    color: _isSaved ? Colors.green[700] : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isSaving || _isSaved ? null : [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          _isSaved ? Icons.check_circle : Icons.save,
                          color: Colors.white,
                          size: 18,
                        ),
                      SizedBox(width: 8),
                      Text(
                        _isSaving ? 'Saving...' : (_isSaved ? 'Saved!' : 'Save Note'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarButton(IconData icon, String label, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}