import 'package:flutter/material.dart';
import "package:mymoneymentor/screens/bot.dart";
import "package:mymoneymentor/screens/news.dart";
import "package:mymoneymentor/screens/profile.dart";
import "package:mymoneymentor/screens/stocks.dart";
import "package:mymoneymentor/screens/learning.dart";
import "package:mymoneymentor/screens/home.dart";

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isFabVisible = true;

  final List<Widget> _screens = [
    FinanceDashboard(), // Home
    LearningPath(),     // Learning
    StockMarket(),      // Progress
    TrendingNews(),     // Quizzes
    AdvisorBot(),       // Settings/Chatbot
    MyProfile(),        // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Image.asset(
              "assets/images/logo.png",
              fit: BoxFit.contain,
              height: 60,
            ),
            const SizedBox(width: 8),
            const Text(
              "MyMoneyMentor",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 3; // example: trending news
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 5; // profile
              });
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex, // prevent index error
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _isFabVisible = true;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learning"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Progress"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Quizzes"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _selectedIndex = 4; // AI / Chatbot page
            _isFabVisible = false;
          });
        },
        backgroundColor: const Color.fromARGB(255, 3, 221, 137),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
