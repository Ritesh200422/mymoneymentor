import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mymoneymentor/screens/traditional_lessons.dart';
import 'quiz_result.dart';
import 'wrong_answers.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class QuizScreen extends StatefulWidget {
  final String lessonId;
  final String docId;
  final String from;

  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.docId,
    required this.from,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int currentQuestion = 0;
  int correctAnswers = 0;
  bool answered = false;
  int? selectedOptionIndex;
  List<Map<String, dynamic>> quizList = [];
  List<int> wrongIndexes = [];
  bool _navigated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  /// Get the appropriate backend URL based on platform
  String _getBackendUrl() {
    if (kIsWeb) {
      // Web: use localhost
      return "http://127.0.0.1:8000";
    } else if (Platform.isAndroid) {
      // Android emulator: use 10.0.2.2 to access host machine's localhost
      // For physical device, replace with your computer's local IP (e.g., "http://192.168.1.100:8000")
      return "http://10.0.2.2:8000";
    } else if (Platform.isIOS) {
      // iOS simulator: use localhost
      return "http://127.0.0.1:8000";
    } else {
      // Fallback
      return "http://127.0.0.1:8000";
    }
  }

  Future<void> _initQuiz() async {
    await _fetchQuizFromBackend(); // Wait until backend finishes
    await _loadQuizFromFirestore(); // Then load it into UI
  }

  Future<void> _fetchQuizFromBackend() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final baseUrl = _getBackendUrl();
      final url = Uri.parse(
        "$baseUrl/api/generate_quiz/${user.uid}/${widget.from}/${widget.lessonId}",
      );

      debugPrint("🌐 Fetching quiz from: $url");

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout - check backend URL');
            },
          );

      if (response.statusCode == 200) {
        debugPrint("✅ Quiz generated successfully from backend");
      } else {
        debugPrint("❌ Failed to generate quiz: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching quiz: $e");
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error connecting to server: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadQuizFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizzes')
          .doc("${widget.from}_${widget.lessonId}")
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          quizList = List<Map<String, dynamic>>.from(data['quiz'] ?? []);
          _isLoading = false;
        });
      } else {
        debugPrint("⚠️ Quiz not found in Firestore yet.");
        // Wait a bit and retry once
        await Future.delayed(const Duration(seconds: 2));
        final retryDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('quizzes')
            .doc("${widget.from}_${widget.lessonId}")
            .get();

        if (retryDoc.exists) {
          final data = retryDoc.data() as Map<String, dynamic>;
          setState(() {
            quizList = List<Map<String, dynamic>>.from(data['quiz'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Firestore load error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateWrongAnswers() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quizzes')
        .doc("${widget.from}_${widget.lessonId}")
        .set({'wrongAnswers': wrongIndexes}, SetOptions(merge: true));
  }

  void navigateToNextScreen(User user) async {
    if (_navigated || !mounted) return;
    _navigated = true;

    await updateWrongAnswers();

    if (wrongIndexes.isNotEmpty) {
      final wrongQuestions = wrongIndexes
          .where((i) => i >= 0 && i < quizList.length)
          .map((i) => quizList[i])
          .toList();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WrongAnswersScreen(
            wrongQuestions: wrongQuestions,
            totalQuestions: quizList.length,
            correctAnswers: correctAnswers,
            quizId: widget.docId,
            userId: user.uid,
            lessonId: widget.lessonId,
            from: widget.from,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quizId: widget.docId,
            userId: user.uid,
            correctAnswers: correctAnswers,
            totalQuestions: quizList.length,
            xpEarned: correctAnswers * 10,
            lessonId: widget.lessonId,
            from: widget.from,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Please log in to access this quiz.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.tealAccent),
              const SizedBox(height: 16),
              const Text(
                "Generating your quiz...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb
                    ? "Web Mode"
                    : Platform.isAndroid
                    ? "Android Mode"
                    : "iOS Mode",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (quizList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "No quiz available.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withAlpha(51),
                  foregroundColor: Colors.tealAccent,
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (currentQuestion >= quizList.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToNextScreen(user);
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    final quiz = quizList[currentQuestion];
    final options = List<String>.from(quiz['options'] ?? []);
    final correctIndex = quiz['correctIndex'] ?? -1;

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final questionFontSize = isSmallScreen ? 14.0 : 16.0;
    final optionFontSize = isSmallScreen ? 13.0 : 14.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Quiz ${currentQuestion + 1}/${quizList.length}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 22,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TraditionalLessonsScreen(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (currentQuestion + 1) / quizList.length,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.tealAccent,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Question
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['question'] ?? "",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: questionFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Options
                      ...List.generate(options.length, (i) {
                        bool isSelected = selectedOptionIndex == i;
                        bool isCorrect = answered && i == correctIndex;
                        bool isWrong =
                            answered && isSelected && i != correctIndex;

                        return GestureDetector(
                          onTap: answered
                              ? null
                              : () {
                                  setState(() {
                                    selectedOptionIndex = i;
                                    answered = true;

                                    if (i == correctIndex) {
                                      correctAnswers++;
                                    } else {
                                      wrongIndexes.add(currentQuestion);
                                    }
                                  });
                                },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 6 : 8,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.withAlpha(71)
                                  : isWrong
                                  ? Colors.red.withAlpha(71)
                                  : Colors.grey[850],
                              border: Border.all(
                                color: isCorrect
                                    ? Colors.green
                                    : isWrong
                                    ? Colors.red
                                    : Colors.tealAccent.withAlpha(71),
                                width: isCorrect || isWrong ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                if (answered)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : isWrong
                                          ? Icons.cancel
                                          : Icons.radio_button_unchecked,
                                      color: isCorrect
                                          ? Colors.green
                                          : isWrong
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    options[i],
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: optionFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Next button
              if (answered)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentQuestion++;
                          answered = false;
                          selectedOptionIndex = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.withAlpha(51),
                        foregroundColor: Colors.tealAccent,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        currentQuestion + 1 < quizList.length
                            ? "Next Question"
                            : "Finish Quiz",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
