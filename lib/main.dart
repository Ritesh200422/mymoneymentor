import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// MyApp as StatelessWidget, only wraps MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Image.asset(
              "assets/logo.png",
              fit: BoxFit.contain,
              height: 60,
            ),
            const SizedBox(width:0), // small gap between logo & text
            const Text(
              "MyMoneyMentor",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
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
              color: _selectedIndex == 5
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 5;
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
              });
            },
          ),

          // Profile
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: _selectedIndex == 6
                  ? const Color.fromARGB(255, 3, 221, 137)
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 6;
              });
            },
          ),
        ],
      ),


      body: const Center(
        child: Text(
          "",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
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

            // School
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
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
                        "School",
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _selectedIndex = 4; // optional: handle FAB selection
          });
        },
        backgroundColor: Color.fromARGB(255, 3, 221,137),
        child: const Icon(Icons.smart_toy,color: Colors.white,),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
