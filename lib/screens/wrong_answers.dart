import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_result.dart';

class WrongAnswersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> wrongQuestions;
  final int totalQuestions;
  final int correctAnswers;
  final String quizId;
  final String userId;
  final String lessonId;
  final String from;

  const WrongAnswersScreen({
    super.key,
    required this.wrongQuestions,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.quizId,
    required this.userId,
    required this.lessonId,
    required this.from,
  });

  @override
  State<WrongAnswersScreen> createState() => _WrongAnswersScreenState();
}

class _WrongAnswersScreenState extends State<WrongAnswersScreen> {
  int currentQuestion = 0;
  int retryCorrectCount = 0;
  int? selectedOptionIndex;
  bool answered = false;
  bool finished = false;
  List<int> remainingWrongIndexes = [];

  @override
  void initState() {
    super.initState();

    // If no wrong questions, go directly to result
    if (widget.wrongQuestions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToResultScreen());
      return;
    }

    remainingWrongIndexes = List.generate(
      widget.wrongQuestions.length,
      (i) => i,
    );
  }

  void handleAnswer(int index, int correctIndex) {
    if (!mounted) return;

    setState(() {
      selectedOptionIndex = index;
      answered = true;

      if (index == correctIndex) {
        retryCorrectCount++;
        remainingWrongIndexes.remove(currentQuestion);
      }
    });

    // If all wrongs are now fixed, move to result automatically
    Future.delayed(const Duration(milliseconds: 700), () {
      if (remainingWrongIndexes.isEmpty && mounted) {
        setState(() => finished = true);
        Future.delayed(const Duration(milliseconds: 500), _goToResultScreen);
      }
    });
  }

  void nextQuestion() {
    if (!mounted) return;

    if (remainingWrongIndexes.isEmpty) {
      _goToResultScreen();
      return;
    }

    setState(() {
      answered = false;
      selectedOptionIndex = null;

      // Move to next unanswered wrong question
      do {
        currentQuestion = (currentQuestion + 1) % widget.wrongQuestions.length;
      } while (!remainingWrongIndexes.contains(currentQuestion) &&
          remainingWrongIndexes.isNotEmpty);
    });
  }

  void _goToResultScreen() {
    if (!mounted) return;

    final totalCorrect = widget.correctAnswers + retryCorrectCount;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          correctAnswers: totalCorrect,
          totalQuestions: widget.totalQuestions,
          xpEarned: totalCorrect * 10,
          quizId: widget.quizId,
          userId: widget.userId,
          lessonId: widget.lessonId,
          from: widget.from,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    if (widget.wrongQuestions.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    final quiz = widget.wrongQuestions[currentQuestion];
    final options = List<String>.from(quiz['options'] ?? []);
    final correctIndex = quiz['correctIndex'] ?? -1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Try Again!",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              quiz['question'] ?? "",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ...List.generate(options.length, (i) {
              bool isSelected = selectedOptionIndex == i;
              bool isCorrect = answered && i == correctIndex;
              bool isWrong = answered && isSelected && i != correctIndex;

              return GestureDetector(
                onTap: answered ? null : () => handleAnswer(i, correctIndex),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withAlpha(77)
                        : isWrong
                        ? Colors.red.withAlpha(77)
                        : Colors.grey[850],
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : isWrong
                          ? Colors.red
                          : Colors.tealAccent.withAlpha(77),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    options[i],
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),
            if (answered && remainingWrongIndexes.isNotEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.withAlpha(51),
                    foregroundColor: Colors.tealAccent,
                  ),
                  child: const Text("Next Question"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
