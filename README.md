# 🧠 Nexus: AI Study Assistant

<div align="center">

![Nexus Banner](https://img.shields.io/badge/Nexus-AI%20Study%20Assistant-7F77DD?style=for-the-badge&logo=flutter&logoColor=white)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Connected-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Groq AI](https://img.shields.io/badge/Groq-AI%20Powered-F54703?style=flat-square)](https://groq.com)
[![Whisper](https://img.shields.io/badge/Whisper-Voice%20AI-412991?style=flat-square)](https://openai.com/whisper)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**Transform your handwritten notes into digital knowledge with AI.**

Scan notes → Generate quizzes → Create flashcards → Track your study time.

</div>

---

## 📱 Screenshots

| | | |
|---|---|---|
| ![](screenshots/01_splash.jpeg) | ![](screenshots/02_dashboard.jpeg) | ![](screenshots/03_camera.jpeg) |
| ![](screenshots/04_extracting.jpeg) | ![](screenshots/05_extracted_text.jpeg) | ![](screenshots/06_flashcards.jpeg) |
| ![](screenshots/07_quiz.jpeg) | ![](screenshots/08_quiz_results.jpeg) | ![](screenshots/09_quiz_review.jpeg) |
| ![](screenshots/10_paste_text.jpeg) | ![](screenshots/11_study_timer.jpeg) | ![](screenshots/12_weekly_progress.jpeg) |
| ![](screenshots/13_voice_summarizer.jpeg) | ![](screenshots/14_profile.jpeg) | ![](screenshots/15_catalog.jpeg) |
| ![](screenshots/16_login.jpeg) | ![](screenshots/17_reset_password.jpeg) | ![](screenshots/18_signup.jpeg) |

---

## ✨ Features

### 📸 Smart Note Scanner
- Point your camera at any handwritten or printed notes
- OCR + AI extracts text instantly
- Shows word count, character count, and line count
- Edit extracted text before processing
- Gallery import supported

### 🧪 AI Quiz Generator
- Generates 10 intelligent multiple-choice questions from your notes
- Powered by **Groq AI (Llama 3.1)**
- Marks your answers in real time
- Shows correct answer with detailed explanation for every question
- Results saved automatically to history

### 🃏 Flashcard Generator
- Creates 10 flip-card flashcards from your content
- Tap to reveal answer
- Progress tracker (Card 1 of 10, 10% complete)
- Shuffle and retry support

### ⏱️ Study Timer
- Pomodoro-style sessions: 15, 25, 30, 45, 60, 90 minutes
- Day streak tracker with 🔥 indicator
- Weekly progress graph (last 7 days)
- Session count and total study time tracking

### 🎙️ Voice Summarizer
- Speak in **Urdu or English**
- Powered by **Whisper AI**: real-time transcription
- AI generates structured summary of what you said
- Duration, word count, and summary word count displayed
- Copy transcript or summary instantly

### 📂 History & Catalog
- All quizzes, scanned notes, and voice notes saved to Firebase
- Organized catalog view
- Re-attempt any quiz from history
- View all previous extracted text

### 🔐 Authentication
- Email + Password login and signup
- OTP-based password reset (6-digit code via email)
- Firebase Auth: verified accounts only
- Persistent login session

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **AI: Quiz & Summary** | Groq AI API (Llama 3.1) |
| **AI: Voice** | Whisper AI |
| **Backend & Database** | Firebase Firestore |
| **Authentication** | Firebase Auth (OTP) |
| **OCR** | Google ML Kit |
| **State Management** | Provider / setState |
| **Storage** | Firebase Storage |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code
- Firebase project configured
- Groq API key (free at console.groq.com)

### Installation

```bash
# Clone the repository
git clone https://github.com/hamzmzjhdjd/nexus-ai-study-assistant.git

# Navigate to project
cd nexus-ai-study-assistant

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Environment Setup

Create a `.env` file in the root directory:

```env
GROQ_API_KEY=your_groq_api_key_here
```

Add your `google-services.json` from Firebase Console to `/android/app/`.

---

## 🎯 How It Works

```
📸 Camera / Gallery / Paste Text
         ↓
🔍 OCR extracts raw text
         ↓
🤖 Groq AI processes content
         ↓
    ┌────┴────┐
    ↓         ↓
📝 Quiz    🃏 Flashcards
    ↓
✅ Results + Explanation
         ↓
💾 Saved to Firebase History
```

---

## 🌟 Why Nexus?

Most students struggle with converting passive reading into active learning. Nexus solves this by:

- **Eliminating manual note-taking**: just scan and go
- **Forcing active recall**: quizzes beat re-reading every time
- **Tracking consistency**: streaks and weekly graphs build habits
- **Supporting Urdu speakers**: voice notes work in Urdu and English

---

## 👨‍💻 Built By

**Muhammad Hamza**
Final Year CS Student, Capital University of Science and Technology (CUST)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat-square&logo=linkedin)](https://linkedin.com/in/YOUR_LINKEDIN_HERE)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat-square&logo=github)](https://github.com/hamzmzjhdjd)

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <strong>If this project helped you, please ⭐ star the repo!</strong>
</div>