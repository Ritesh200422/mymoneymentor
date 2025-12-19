import 'package:flutter/material.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple,
            child: Text("N", style: TextStyle(fontSize: 40, color: Colors.white)),
          ),
          SizedBox(height: 10),
          Center(child: Text("Edit", style: TextStyle(color: Colors.blue))),
          SizedBox(height: 20),
          _InfoItem(label: "Full name", value: "Nikhil Niranjan Achar"),
          _InfoItem(label: "Date of Birth", value: "**/**/2005"),
          _InfoItem(label: "Mobile Number", value: "*****22005"),
          _InfoItem(label: "Email", value: "nik********5@gmail.com"),
          _InfoItem(label: "PAN number", value: "******094K"),
          _InfoItem(label: "Gender", value: "Male"),
          _InfoItem(label: "Marital Status", value: "Single"),
          _InfoItem(label: "Income Range", value: "1-5 Lacs"),
          _InfoItem(label: "Father's Name", value: "Niranjan R"),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
      ],
    );
  }
}
