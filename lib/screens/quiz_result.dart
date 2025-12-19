import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:mymoneymentor/screens/streak.dart';
import 'traditional_lessons.dart';
import 'nontraditional_lessons.dart';

class QuizResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;
  final String quizId;
  final String userId;
  final String lessonId;
  final String from;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.xpEarned,
    required this.quizId,
    required this.userId,
    required this.lessonId,
    required this.from,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isUpdating = true;
  String? _streakMessage;
  late ConfettiController _confettiController;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _updateQuizAndXP();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _updateQuizAndXP() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(widget.userId);

      // ✅ 1. Mark quiz as completed
      await firestore
          .collection('users')
          .doc(widget.userId)
          .collection('quizzes')
          .doc("${widget.from}_${widget.lessonId}")
          .set({
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // ✅ 2. Update XP + Streak inside transaction
      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final userData = userSnapshot.data() ?? {};

        int currentXP = (userData['xp'] ?? 0) as int;
        int currentStreak = (userData['streak'] ?? 0) as int;
        Timestamp? lastQuizTimestamp = userData['lastQuizDate'] as Timestamp?;
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        int newStreak = currentStreak;
        bool streakUpdated = false;

        if (lastQuizTimestamp != null) {
          DateTime lastQuizDate = lastQuizTimestamp.toDate();
          DateTime lastDay = DateTime(
            lastQuizDate.year,
            lastQuizDate.month,
            lastQuizDate.day,
          );
          final difference = today.difference(lastDay).inDays;

          if (difference == 1) {
            newStreak = currentStreak + 1;
            streakUpdated = true;
          } else if (difference > 1) {
            newStreak = 1;
            streakUpdated = true;
          }
        } else {
          newStreak = 1;
          streakUpdated = true;
        }

        transaction.update(userRef, {
          'xp': currentXP + widget.xpEarned,
          'streak': newStreak,
          'lastQuizDate': Timestamp.fromDate(today),
        });

        if (streakUpdated) {
          _streakMessage = "🔥 $newStreak day streak!";
        }
      });

      if (mounted) {
        setState(() => _isUpdating = false);
        _confettiController.play();
      }
    } catch (e) {
      debugPrint("❌ Error updating Firestore: $e");
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _handleNext() {
    if (!mounted) return;

    // 🟢 If streak exists → go to streak celebration page
    if (_streakMessage != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StreakCelebrationScreen(
            streakMessage: _streakMessage!,
            xpEarned: widget.xpEarned,
            from: widget.from,
          ),
        ),
      );
    } else {
      // 🔵 Else → directly go back to lessons
      if (widget.from == 'traditional') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TraditionalLessonsScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const NonTraditionalLessonsScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: _isUpdating
                ? const CircularProgressIndicator(color: Colors.tealAccent)
                : Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.tealAccent,
                          size: 90,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Congratulations!",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "+${widget.xpEarned} XP Earned",
                          style: GoogleFonts.poppins(
                            color: Colors.tealAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.withAlpha(51),
                            foregroundColor: Colors.tealAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _streakMessage != null ? "Next" : "Back to Lessons",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // 🎊 Confetti Animation
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.tealAccent,
              Colors.purpleAccent,
              Colors.orangeAccent,
              Colors.pinkAccent,
            ],
          ),
        ],
      ),
    );
  }
}
