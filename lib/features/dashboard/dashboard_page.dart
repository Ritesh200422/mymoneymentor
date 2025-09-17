import 'package:flutter/material.dart';
import 'package:mymoneymentor/screens/Learning.dart';
import 'package:mymoneymentor/screens/bot.dart';
import 'package:mymoneymentor/screens/home.dart';
import 'package:mymoneymentor/screens/news.dart';
import 'package:mymoneymentor/screens/profile.dart';
import 'package:mymoneymentor/screens/stocks.dart';

// Dashboard Screen (after login)
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Home_Page(),
    Trending_News(),
    Stock_Marcket(),
    Learning_Path(),
    Advisor_Bot(),
    My_Profile(),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none, // allow text to go outside if needed
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.contain,
                  height: 70,
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 🔍 Search
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

          // 🔔 Notifications
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

          // 👤 Profile
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

      // 🔽 Bottom Nav
      bottomNavigationBar: BottomAppBar(
        color: Colors.black87,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomItem(Icons.home, "Home", 0),
            _buildBottomItem(Icons.newspaper, "News", 1),
            _buildBottomItem(Icons.show_chart_outlined, "Stocks", 2),
            _buildBottomItem(Icons.school_rounded, "Learning", 3),
          ],
        ),
      ),

      // 🤖 Floating Action Button → AI Bot
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 4;
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

  Widget _buildBottomItem(IconData icon, String label, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isFabVisible = true;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: _selectedIndex == index
                ? const Color.fromARGB(255, 3, 221, 137)
                : Colors.white,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _selectedIndex == index
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
