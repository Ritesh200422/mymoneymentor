import 'package:flutter/material.dart';

class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark theme
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage("assets/user.png"), // user profile pic
            ),
            const SizedBox(width: 10),
            const Text(
              "Welcome, Mueez 👋",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.leaderboard, color: Colors.white),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Goal / Progress Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Goal",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text("Stocks Basics | 5/10 Lessons",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text("Continue Learning"),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row (like Hasanat, Verses, etc.)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Progress Score", "85%", Colors.purple),
                _buildStatCard("Topics Done", "12", Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Time Spent", "2h 15m", Colors.orange),
                _buildStatCard("Quizzes Taken", "5", Colors.green),
              ],
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learning"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Progress"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Quizzes"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // Reusable Stat Card Widget
  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.circle, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
