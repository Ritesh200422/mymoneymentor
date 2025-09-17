import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // match your app theme
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2, // 2 cards per row
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildHomeCard(Icons.newspaper, "News", Colors.blue),
          _buildHomeCard(Icons.show_chart, "Stocks", Colors.green),
          _buildHomeCard(Icons.school, "Learning", Colors.orange),
          _buildHomeCard(Icons.account_circle, "Profile", Colors.purple),
        ],
      ),
    );
  }

  Widget _buildHomeCard(IconData icon, String title, Color color) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
