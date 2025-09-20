import 'package:flutter/material.dart';
import "package:mymoneymentor/screens/bot.dart";
import "package:mymoneymentor/screens/news.dart";
import "package:mymoneymentor/screens/profile.dart";
import "package:mymoneymentor/screens/stocks.dart";
import "package:mymoneymentor/screens/learning.dart";
import "package:mymoneymentor/screens/home.dart";

// MyApp as StatelessWidget, only wraps MaterialApp
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

// StatefulWidget for the screen to manage selected icon
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Tracks which icon is selected
  final List<Widget> _screens = [
    HomePage(),
    TrendingNews(),
    StockMarket(),
    LearningPath(),
    AdvisorBot(),
    MyProfile(),
  ];
  bool _isFabVisible = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
            const SizedBox(width: 0), // small gap between logo & text
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
          // Search
          IconButton(
            icon: Icon(
              Icons.search,
              color: _selectedIndex == 6
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 6;
                _isFabVisible = true;
              });
            },
          ),

          // Notifications
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: _selectedIndex == 7
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 7;
                _isFabVisible = true;
              });
            },
          ),

          // Profile
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: _selectedIndex == 5
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 5;
                _isFabVisible = true;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black87,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                      _isFabVisible = true;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        size: 24,
                        color: _selectedIndex == 0
                            ? const Color.fromARGB(255, 3, 221, 137)
                            : Colors.white,
                      ),
                      Text(
                        "Home",
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedIndex == 0
                              ? const Color.fromARGB(255, 3, 221, 137)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // News
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                      _isFabVisible = true;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.newspaper,
                        size: 24,
                        color: _selectedIndex == 1
                            ? const Color.fromARGB(255, 3, 221, 137)
                            : Colors.white,
                      ),
                      Text(
                        "News",
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedIndex == 1
                              ? const Color.fromARGB(255, 3, 221, 137)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Chart
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                      _isFabVisible = true;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_outlined,
                        size: 24,
                        color: _selectedIndex == 2
                            ? const Color.fromARGB(255, 3, 221, 137)
                            : Colors.white,
                      ),
                      Text(
                        "Stocks",
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedIndex == 2
                              ? const Color.fromARGB(255, 3, 221, 137)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // lEARNING
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                      _isFabVisible = true;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 24,
                        color: _selectedIndex == 3
                            ? const Color.fromARGB(255, 3, 221, 137)
                            : Colors.white,
                      ),
                      Text(
                        "Learning",
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedIndex == 3
                              ? const Color.fromARGB(255, 3, 221, 137)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 4; // AI / Chatbot page
                  _isFabVisible = false; // hide FAB
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
