import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';  // NEW: Added for gallery
import 'dart:io';
import 'ocr_service.dart';
import 'note_display_screen.dart';

// ==============================================================================
// PROFESSIONAL CAMERA SCREEN - Clean, Minimal, Premium Quality
// ==============================================================================
// Design Philosophy: "Less is More"
// - Clean interface, no clutter
// - Subtle NEXUS branding
// - Professional like Apple/Google apps
// NEW: Gallery picker added!
// ==============================================================================

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;
  bool _isTakingPicture = false;
  bool _isProcessingOCR = false;

  // NEW: Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();

      setState(() {
        _capturedImage = image;
        _isTakingPicture = false;
      });
    } catch (e) {
      setState(() => _isTakingPicture = false);
    }
  }

  // ==============================================================================
  // NEW METHOD: Pick image from gallery
  // ==============================================================================
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,  // High quality
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1F1F1F),
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to pick image from gallery'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _processImageWithOCR() async {
    if (_capturedImage == null) return;

    setState(() => _isProcessingOCR = true);

    try {
      final extractedText = await OCRService.extractText(_capturedImage!.path);

      setState(() => _isProcessingOCR = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDisplayScreen(
              extractedText: extractedText,
              imagePath: _capturedImage!.path,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingOCR = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1F1F1F),
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to extract text. Please try again.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          _capturedImage != null ? _buildImagePreview() : _buildCameraPreview(),

          // Top bar overlay
          _buildTopBar(),

          // Processing overlay
          if (_isProcessingOCR) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // ==============================================================================
  // TOP BAR - Clean and minimal (UPDATED with gallery button)
  // ==============================================================================
  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            Spacer(),

            // Title with subtle NEXUS branding
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
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
                    'Scan Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            // NEW: Gallery button (only show when camera is active)
            if (_capturedImage == null)
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            else
              SizedBox(width: 40), // Balance when showing image preview
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // CAMERA PREVIEW - Full screen with corner guides
  // ==============================================================================
  Widget _buildCameraPreview() {
    if (_cameraController == null || _initializeControllerFuture == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
          strokeWidth: 2,
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              // Camera preview
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              ),

              // Corner guides for framing
              Positioned.fill(
                child: CustomPaint(
                  painter: CornerGuidesPainter(),
                ),
              ),

              // Capture button at bottom
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _isTakingPicture ? null : _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isTakingPicture
                            ? Colors.white.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                      child: _isTakingPicture
                          ? Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Container(
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Instruction text (UPDATED)
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tap gallery icon to choose existing photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // ==============================================================================
  // IMAGE PREVIEW - Clean preview with action buttons (UPDATED button text)
  // ==============================================================================
  Widget _buildImagePreview() {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Image.file(
                File(_capturedImage!.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Extract button
                GestureDetector(
                  onTap: _processImageWithOCR,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
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
                        Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Extract Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Retake button (UPDATED text for clarity)
                GestureDetector(
                  onTap: () {
                    setState(() => _capturedImage = null);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white70, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Choose Another',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================================
  // PROCESSING OVERLAY - Clean loading state
  // ==============================================================================
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF1F1F1F),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                      strokeWidth: 3,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            Text(
              'Extracting Text',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Using AI to read your document',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// CORNER GUIDES PAINTER - Subtle frame guides
// ==============================================================================
class CornerGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final cornerLength = 40.0;
    final margin = 40.0;

    // Top-left
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerLength),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==============================================================================
// ✅ CHANGES MADE (Minimal, non-disruptive):
// ==============================================================================
// 1. ✅ Added: import 'package:image_picker/image_picker.dart';
// 2. ✅ Added: final ImagePicker _picker = ImagePicker(); (state variable)
// 3. ✅ Added: _pickFromGallery() method
// 4. ✅ Modified: _buildTopBar() - added gallery icon button
// 5. ✅ Modified: instruction text - mentions gallery option
// 6. ✅ Modified: "Retake Photo" → "Choose Another" (clearer)
//
// Everything else stays EXACTLY the same!
// Your UI, colors, animations - all untouched! ✅
// ==============================================================================