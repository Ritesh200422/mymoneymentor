import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymoneymentor/screens/learning.dart';
import 'quiz.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;
  final String docId;
  final String from;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.docId,
    required this.from,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Lesson Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                    builder: (context) => const LearningScreen(),
                  ),
                ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore
            .collection('learning')
            .doc(widget.docId)
            .collection(widget.from)
            .doc(widget.lessonId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Lesson not found.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? "Lesson";
          final topics = List<Map<String, dynamic>>.from(data['topics'] ?? []);

          if (topics.isEmpty) {
            return Center(
              child: Text(
                "No topics found.",
                style: GoogleFonts.nunito(color: Colors.white70),
              ),
            );
          }

          // Keep index within range
          if (topics.isEmpty) {
            return const Center(
              child: Text(
                "No topics available.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          int totalTopics = topics.length;
          if (_currentIndex < 0) _currentIndex = 0;
          if (_currentIndex >= totalTopics) _currentIndex = totalTopics - 1;

          final currentTopic = topics[_currentIndex];

          final topicTitle = currentTopic.keys.first;
          final topicContent = currentTopic.values.first;
          final progress = (_currentIndex + 1) / topics.length;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Lesson Title
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.tealAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // ✅ Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: Colors.tealAccent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 25),

                // ✅ Topic Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.tealAccent.withAlpha(71),
                      ),
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Text(
                          topicTitle,
                          style: GoogleFonts.poppins(
                            color: Colors.tealAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MarkdownBody(
                          data: topicContent,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.6,
                            ),
                            strong: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(
                              color: Colors.tealAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // ✅ Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔙 Previous
                    if (_currentIndex > 0)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.withAlpha(51),
                          foregroundColor: Colors.tealAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Previous"),
                      )
                    else
                      const SizedBox(width: 120),

                    // ➡️ Next or Quiz
                    _currentIndex < topics.length - 1
                        ? ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentIndex++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.withAlpha(51),
                              foregroundColor: Colors.tealAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Next"),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    lessonId: widget.lessonId,
                                    docId: widget.docId,
                                    from: widget.from,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.withAlpha(51),
                              foregroundColor: Colors.tealAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.quiz),
                            label: const Text("Take Quiz"),
                          ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
