import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'traditional_lessons.dart';
import 'nontraditional_lessons.dart';

class StreakCelebrationScreen extends StatefulWidget {
  final String streakMessage;
  final int xpEarned;
  final String from;

  const StreakCelebrationScreen({
    super.key,
    required this.streakMessage,
    required this.xpEarned,
    required this.from,
  });

  @override
  State<StreakCelebrationScreen> createState() =>
      _StreakCelebrationScreenState();
}

class _StreakCelebrationScreenState extends State<StreakCelebrationScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _confettiController.play();
    _animController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🎊 Confetti Animation (background)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              Colors.amberAccent,
              Colors.deepPurpleAccent,
              Colors.tealAccent,
              Colors.orangeAccent,
            ],
            emissionFrequency: 0.08,
            numberOfParticles: 15,
            gravity: 0.2,
          ),

          // 🎉 Centered Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // keeps it vertically compact
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                      size: 120,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.streakMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.from == 'traditional') {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TraditionalLessonsScreen(),
                            ),
                            (route) => false,
                          );
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NonTraditionalLessonsScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.withAlpha(51),
                        foregroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
