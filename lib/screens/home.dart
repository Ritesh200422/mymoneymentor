// lib/screens/home.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'traditional_lessons.dart';
import 'nontraditional_lessons.dart';

/// ---------- Simple module model ----------
class Module {
  final String id; // 'traditional' | 'nontraditional'
  final String title;
  final int totalLessons;

  Module({required this.id, required this.title, required this.totalLessons});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // derived from Firestore
  List<Module> modules = [];
  bool _loading = true;

  // user data
  int quizzesTaken = 0;
  int learningStreak = 0;
  int xp = 0;
  String userName = "User";

  // per-module progress (map moduleId -> completedCount)
  final Map<String, int> _moduleCompletedCount = {};
  final Map<String, int> _moduleTotalLessons = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _loading = true);
    try {
      // master document id used in your app
      const String learningDocId = 's3dJjQIcaI4XDN2b80LD';

      // modules we show — map to collection names in Firestore
      final moduleDefinitions = [
        {'id': 'traditional', 'title': 'Traditional Finance'},
        {'id': 'nontraditional', 'title': 'Non-Traditional Finance'},
      ];

      final List<Module> loadedModules = [];

      // fetch lessons count for each module & build Module objects
      for (var def in moduleDefinitions) {
        final query = await _firestore
            .collection('learning')
            .doc(learningDocId)
            .collection(def['id']!)
            .orderBy('order')
            .get();

        final lessons = query.docs;
        final total = lessons.length;

        loadedModules.add(
          Module(id: def['id']!, title: def['title']!, totalLessons: total),
        );

        _moduleTotalLessons[def['id']!] = total;
      }

      // fetch user data if logged in
      if (_uid != null) {
        final userDoc = await _firestore.collection('users').doc(_uid).get();
        final udata = userDoc.exists ? (userDoc.data() ?? {}) : {};

        xp = (udata['xp'] ?? 0) as int;
        learningStreak = (udata['streak'] ?? 0) as int;
        userName = (udata['name'] ?? udata['displayName'] ?? 'User') as String;

        // fetch user quizzes and compute per-module completion counts
        final quizSnapshot = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('quizzes')
            .get();

        quizzesTaken = quizSnapshot.docs.length;

        // reset counts
        _moduleCompletedCount.clear();
        for (var m in loadedModules) {
          _moduleCompletedCount[m.id] = 0;
        }

        for (var doc in quizSnapshot.docs) {
          final id = doc.id; // e.g. 'traditional_lesson_1'
          final data = doc.data();
          final completed = data['completed'] == true;
          if (!completed) continue;

          if (id.startsWith('traditional_')) {
            _moduleCompletedCount['traditional'] =
                (_moduleCompletedCount['traditional'] ?? 0) + 1;
          } else if (id.startsWith('nontraditional_')) {
            _moduleCompletedCount['nontraditional'] =
                (_moduleCompletedCount['nontraditional'] ?? 0) + 1;
          }
        }
      }

      setState(() {
        modules = loadedModules;
      });
    } catch (e, st) {
      debugPrint("Error loading home data: $e\n$st");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openModule(Module module) {
    if (module.id == 'traditional') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TraditionalLessonsScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NonTraditionalLessonsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;

    // Responsive breakpoints
    final bool isSmallPhone = screenWidth < 360;
    final bool isMediumPhone = screenWidth >= 360 && screenWidth < 400;
    final bool isLargePhone = screenWidth >= 400;

    // Dynamic padding based on screen size
    final double horizontalPadding = isSmallPhone ? 12 : 16;
    final double verticalPadding = isSmallPhone ? 12 : 18;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              )
            : RefreshIndicator(
                onRefresh: _loadHomeData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // HEADER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding,
                          horizontalPadding,
                          8,
                        ),
                        child: _buildHeader(isSmallPhone),
                      ),
                    ),

                    // BODY
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),

                            // MODULE CARDS
                            _buildModuleSection(screenWidth),

                            SizedBox(height: isSmallPhone ? 14 : 18),

                            // STATS
                            _buildSectionTitle("Your Stats"),
                            const SizedBox(height: 12),
                            _buildStatsRow(isSmallPhone),

                            SizedBox(height: isSmallPhone ? 14 : 18),

                            // RECOMMENDED
                            _buildSectionTitle("Recommended"),
                            const SizedBox(height: 8),
                            _buildRecommendedList(screenWidth),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------- RESPONSIVE UI COMPONENTS ----------

  Widget _buildHeader(bool isSmallPhone) {
    // Get first letter of name, fallback to 'U' if empty
    final String firstLetter = userName.isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';

    return Row(
      children: [
        // Avatar - smaller on small phones
        Container(
          width: isSmallPhone ? 52 : 62,
          height: isSmallPhone ? 52 : 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6EE7B7), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              firstLetter,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallPhone ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, $userName",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallPhone ? 16 : 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Level up your finance skills today ✨",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmallPhone ? 12 : 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _loadHomeData,
          icon: Icon(
            Icons.refresh,
            color: Colors.white70,
            size: isSmallPhone ? 20 : 24,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildModuleSection(double screenWidth) {
    if (modules.isEmpty) {
      return const Text(
        "No modules found.",
        style: TextStyle(color: Colors.white70),
      );
    }

    // Stack modules vertically on smaller screens
    if (screenWidth < 600) {
      return Column(
        children: modules.map((m) => _buildModuleCard(m, screenWidth)).toList(),
      );
    }

    // Side by side on larger screens
    if (modules.length >= 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: _buildModuleCard(modules[0], screenWidth)),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: _buildModuleCard(modules[1], screenWidth)),
        ],
      );
    }

    return _buildModuleCard(modules.first, screenWidth);
  }

  Widget _buildModuleCard(Module module, double screenWidth) {
    final completed = _moduleCompletedCount[module.id] ?? 0;
    final total = _moduleTotalLessons[module.id] ?? module.totalLessons;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percentText = "${(progress * 100).toStringAsFixed(0)}%";

    final bool isSmallPhone = screenWidth < 360;
    final double progressSize = isSmallPhone ? 80 : 96;
    final double fontSize = isSmallPhone ? 14 : 16;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallPhone ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1724), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title + open button
          Row(
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openModule(module),
                icon: Icon(Icons.play_arrow, size: isSmallPhone ? 16 : 18),
                label: Text(
                  "Open",
                  style: TextStyle(fontSize: isSmallPhone ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1724),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallPhone ? 10 : 12,
                    vertical: isSmallPhone ? 6 : 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Circular progress + info
          Row(
            children: [
              SizedBox(
                width: progressSize,
                height: progressSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: progressSize,
                      height: progressSize,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: isSmallPhone ? 8 : 10,
                        color: Colors.white12,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return SizedBox(
                          width: progressSize,
                          height: progressSize,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: isSmallPhone ? 8 : 10,
                            color: const Color(0xFF6EE7B7),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          percentText,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallPhone ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$completed / $total",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmallPhone ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "XP: $xp",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallPhone ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Streak: $learningStreak days",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallPhone ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _smallChip(
                          Icons.quiz,
                          "$quizzesTaken quizzes",
                          isSmallPhone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallChip(IconData icon, String label, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmall ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
      ],
    );
  }

  Widget _buildStatsRow(bool isSmallPhone) {
    return Row(
      children: [
        Expanded(
          child: _colorStatBox(
            "Overall Progress",
            _overallProgressText(),
            Icons.bar_chart,
            const [Color(0xFF6EE7B7), Color(0xFF3B82F6)],
            isSmallPhone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _colorStatBox(
            "Quizzes Taken",
            "$quizzesTaken",
            Icons.quiz,
            const [Color(0xFFFBCFE8), Color(0xFFFB7185)],
            isSmallPhone,
          ),
        ),
      ],
    );
  }

  String _overallProgressText() {
    int totalLessons = 0;
    int completed = 0;

    for (var m in modules) {
      final t = _moduleTotalLessons[m.id] ?? m.totalLessons;
      totalLessons += t;
      completed += _moduleCompletedCount[m.id] ?? 0;
    }

    if (totalLessons == 0) return "0%";
    final pct = (completed / totalLessons * 100).round();
    return "$pct%";
  }

  Widget _colorStatBox(
    String title,
    String value,
    IconData icon,
    List<Color> gradient,
    bool isSmall,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: isSmall ? 24 : 28),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmall ? 11 : 12,
            ),
          ),
          SizedBox(height: isSmall ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedList(double screenWidth) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('learning')
          .doc('s3dJjQIcaI4XDN2b80LD')
          .collection('traditional')
          .orderBy('order')
          .limit(4)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text(
            "No recommendations yet.",
            style: TextStyle(color: Colors.white70),
          );
        }

        final docs = snap.data!.docs;
        final bool isSmallPhone = screenWidth < 360;

        return SizedBox(
          height: isSmallPhone ? 130 : 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: isSmallPhone ? 10 : 12),
            itemBuilder: (context, idx) {
              final d = docs[idx].data() as Map<String, dynamic>;
              final title = d['title'] ?? 'Lesson';
              final topics = (d['topics'] as List?) ?? [];
              final est = "${(max(1, topics.length) * 3).clamp(5, 60)} min";
              final palette = _lessonPalette(idx);

              // Responsive card width
              final double cardWidth = (screenWidth * 0.65).clamp(
                isSmallPhone ? 140.0 : 160.0,
                280.0,
              );

              return _buildLessonCard(
                title: title,
                time: est,
                palette: palette,
                width: cardWidth,
                isSmall: isSmallPhone,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLessonCard({
    required String title,
    required String time,
    required List<Color> palette,
    required double width,
    required bool isSmall,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: isSmall ? 26 : 30,
          ),
          SizedBox(height: isSmall ? 8 : 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 13 : 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _lessonTag(time, isSmall),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TraditionalLessonsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 10 : 12,
                    vertical: isSmall ? 6 : 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Start",
                  style: TextStyle(fontSize: isSmall ? 12 : 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lessonTag(String text, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
      ),
    );
  }

  List<Color> _lessonPalette(int idx) {
    final palettes = [
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
      [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      [const Color(0xFF34D399), const Color(0xFF10B981)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
    ];
    return palettes[idx % palettes.length];
  }
}
