import 'package:flutter/material.dart';
import 'login_page.dart'; // ✅ Ensure this path is correct

class ProfilePage extends StatelessWidget {
  final String name;
  final String age;
  final String whoYouAre; // ✅ Updated field name
  final String mobile;
  final String gender;

  const ProfilePage({
    super.key,
    required this.name,
    required this.age,
    required this.whoYouAre,
    required this.mobile,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFF5A9BD8),
        actions: [
          IconButton(
            icon: const Text("🚪", style: TextStyle(fontSize: 22)),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildHeader(context),
            const SizedBox(height: 25),
            _buildInfoCard("👤 Name", name),
            _buildInfoCard("🎂 Age", age),
            _buildInfoCard("🧭 Who You Are", whoYouAre), // ✅ Inserted correctly
            _buildInfoCard("📱 Mobile", mobile),
            _buildInfoCard("⚧️ Gender", gender),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF5A9BD8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35, color: Color(0xFF5A9BD8)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              "Welcome, $name",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(
          label.split(" ")[0], // Emoji only
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          label.substring(2), // Remove emoji and space
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
