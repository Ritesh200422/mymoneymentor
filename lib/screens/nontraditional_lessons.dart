import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymoneymentor/screens/lesson_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NonTraditionalLessonsScreen extends StatefulWidget {
  const NonTraditionalLessonsScreen({super.key});

  @override
  State<NonTraditionalLessonsScreen> createState() =>
      _NonTraditionalLessonsScreenState();
}

class _NonTraditionalLessonsScreenState
    extends State<NonTraditionalLessonsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<List<Map<String, dynamic>>> fetchLessonsWithProgress() async {
    if (_uid == null) return [];

    final lessonsSnapshot = await _firestore
        .collection('learning')
        .doc('s3dJjQIcaI4XDN2b80LD')
        .collection('nontraditional')
        .orderBy('order')
        .get();

    final lessons = lessonsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['completed'] = false;
      return data;
    }).toList();

    final userQuizSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('quizzes')
        .get();

    final completedIds = userQuizSnapshot.docs
        .where((doc) => doc['completed'] == true)
        .map((doc) => doc.id)
        .toSet();

    for (var lesson in lessons) {
      final quizId = 'nontraditional_${lesson['id']}';
      if (completedIds.contains(quizId)) {
        lesson['completed'] = true;
      }
    }

    for (int i = 0; i < lessons.length; i++) {
      if (i == 0) {
        lessons[i]['locked'] = false;
      } else {
        lessons[i]['locked'] = !(lessons[i - 1]['completed']);
      }
    }

    return lessons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      /// 🔙 BACK BUTTON ADDED HERE
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Non-Traditional Finance",
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchLessonsWithProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No lessons yet!",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final lessons = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // 🌟 Curved connector path
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CurvedPathPainter(
                          lessonCount: lessons.length,
                          screenWidth: screenWidth,
                        ),
                      ),
                    ),

                    // 🧩 Lesson bubbles
                    Column(
                      children: List.generate(lessons.length, (index) {
                        final isLeft = index.isEven;
                        final lesson = lessons[index];
                        final locked = lesson['locked'] == true;
                        final completed = lesson['completed'] == true;

                        return Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 100,
                            left: isLeft ? 40 : 0,
                            right: isLeft ? 0 : 40,
                          ),
                          child: Align(
                            alignment: isLeft
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: GestureDetector(
                              onTap: locked
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LessonDetailScreen(
                                                lessonId: lesson['id'],
                                                docId: 's3dJjQIcaI4XDN2b80LD',
                                                from: 'nontraditional',
                                              ),
                                          settings: RouteSettings(
                                            arguments: lesson,
                                          ),
                                        ),
                                      );
                                    },
                              child: Column(
                                crossAxisAlignment: isLeft
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: locked
                                              ? Colors.grey[850]
                                              : completed
                                              ? Colors.amber.shade400.withAlpha(
                                                  91,
                                                )
                                              : Colors.black,
                                          border: Border.all(
                                            color: locked
                                                ? Colors.grey
                                                : completed
                                                ? Colors.amberAccent
                                                : Colors.orangeAccent,
                                            width: 2.5,
                                          ),
                                          boxShadow: locked
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: completed
                                                        ? Colors.amberAccent
                                                              .withAlpha(83)
                                                        : Colors.orangeAccent
                                                              .withAlpha(83),
                                                    blurRadius: 20,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                        ),
                                        padding: const EdgeInsets.all(32),
                                        child: Icon(
                                          locked
                                              ? Icons.lock_outline
                                              : completed
                                              ? Icons.check_rounded
                                              : Icons.trending_up_rounded,
                                          color: locked
                                              ? Colors.white60
                                              : Colors.amberAccent,
                                          size: 38,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          height: 28,
                                          width: 28,
                                          decoration: const BoxDecoration(
                                            color: Colors.amberAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lesson['title'] ?? 'Lesson ${index + 1}',
                                    style: GoogleFonts.poppins(
                                      color: locked
                                          ? Colors.grey
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 🌟 Amber curved path painter
class CurvedPathPainter extends CustomPainter {
  final int lessonCount;
  final double screenWidth;

  CurvedPathPainter({required this.lessonCount, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonCount < 2) return;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.amberAccent.withAlpha(83),
          Colors.orangeAccent.withAlpha(83),
        ],
      ).createShader(Rect.fromLTWH(0, 0, screenWidth, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    double startY = 100;
    double stepY = 200;
    double leftX = 120;
    double rightX = screenWidth - 120;

    Offset prev = Offset(leftX, startY);
    path.moveTo(prev.dx, prev.dy);

    for (int i = 1; i < lessonCount; i++) {
      final isLeft = i % 2 == 0;
      final newX = isLeft ? leftX : rightX;
      final newY = startY + i * stepY;

      final control1 = Offset((prev.dx + newX) / 2, prev.dy + stepY / 3);
      final control2 = Offset((prev.dx + newX) / 2, newY - stepY / 3);

      final next = Offset(newX, newY);

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );

      prev = next;
    }

    final glow = Paint()
      ..color = Colors.amberAccent.withAlpha(33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
