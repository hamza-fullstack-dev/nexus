import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── SCANNED NOTES ─────────────────────────────────────────────────────────
  // ✅ ADDED: Save scanned OCR notes to Firebase
  static Future<void> saveScannedNote({
    required String text,
    String? imageUrl,
  }) async {
    if (_uid == null) throw Exception('User not logged in'); // FIXED
    await _db
        .collection('users')
        .doc(_uid)
        .collection('scanned_notes')
        .add({
      'text': text,
      'imageUrl': imageUrl,
      'wordCount': text.split(' ').where((w) => w.isNotEmpty).length,
      'charCount': text.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getScannedNotes() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('scanned_notes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── QUIZ ──────────────────────────────────────────────────────────────────
  static Future<void> saveQuiz({
    required String title,
    required List<Map<String, dynamic>> questions,
    required int score,
    required int total,
  }) async {
    if (_uid == null) throw Exception('User not logged in'); // FIXED
    await _db
        .collection('users')
        .doc(_uid)
        .collection('quizzes')
        .add({
      'title': title,
      'questions': questions,
      'score': score,
      'total': total,
      'percentage': ((score / total) * 100).toInt(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getQuizzes() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── VOICE NOTES ───────────────────────────────────────────────────────────
  static Future<void> saveVoiceNote({
    required String transcript,
    required String summary,
    required int durationSeconds,
  }) async {
    if (_uid == null) throw Exception('User not logged in'); // FIXED
    await _db
        .collection('users')
        .doc(_uid)
        .collection('voice_notes')
        .add({
      'transcript': transcript,
      'summary': summary,
      'durationSeconds': durationSeconds,
      'wordCount': transcript.split(' ').where((w) => w.isNotEmpty).length,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getVoiceNotes() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('voice_notes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── STUDY TIMER ───────────────────────────────────────────────────────────
  static Future<void> saveTimerSession({
    required int minutes,
  }) async {
    if (_uid == null) throw Exception('User not logged in'); // FIXED
    final now = DateTime.now();
    final dayKey = '${now.year}_${now.month}_${now.day}';

    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection('timer_sessions')
        .doc(dayKey);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({
        'totalMinutes': FieldValue.increment(minutes),
        'sessions': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'date': dayKey,
        'totalMinutes': minutes,
        'sessions': 1,
        'year': now.year,
        'month': now.month,
        'day': now.day,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<QuerySnapshot> getTimerSessions() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('timer_sessions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<Map<String, int>> getLast30DaysMinutes() async {
    if (_uid == null) return {};
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('timer_sessions')
        .get();

    final Map<String, int> result = {};
    for (final doc in snapshot.docs) {
      result[doc.id] = (doc['totalMinutes'] as num).toInt();
    }
    return result;
  }
}