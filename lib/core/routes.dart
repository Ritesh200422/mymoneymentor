import 'package:flutter/material.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../screens/learning.dart';
import '../screens/traditional_lessons.dart';
import '../screens/nontraditional_lessons.dart';
import '../screens/lesson_detail.dart';

class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String bot = '/bot';
  static const String learning = '/learning';
  static const String traditional = '/traditional';
  static const String nontraditional = '/nontraditional';
  static const String lesson = '/lesson_detail';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      signup: (context) => const SignupPage(),
      dashboard: (context) => const Dashboard(),
      learning: (context) => const LearningScreen(),
      traditional: (context) => const TraditionalLessonsScreen(),
      nontraditional: (context) => const NonTraditionalLessonsScreen(),
      lesson: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

        return LessonDetailScreen(
          lessonId: args['id'],
          docId: 's3dJjQIcaI4XDN2b80LD',
          from: args['from'], // ✅ Added this line
        );
      },
    };
  }
}
