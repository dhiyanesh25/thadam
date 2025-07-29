import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';
import 'record_page.dart'; // ✅ Ensure this exists

class DashboardPage extends StatefulWidget {
  final String name;
  final String age;
  final String mobile;
  final String gender;
  final String whoYouAre; // ✅ Replaced 'disability'

  const DashboardPage({
    super.key,
    required this.name,
    required this.age,
    required this.mobile,
    required this.gender,
    required this.whoYouAre,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  late String name;
  late String age;
  late String mobile;
  late String gender;
  late String whoYouAre; // ✅ Updated field

  @override
  void initState() {
    super.initState();
    name = widget.name;
    age = widget.age;
    mobile = widget.mobile;
    gender = widget.gender;
    whoYouAre = widget.whoYouAre;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecordPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            name: name,
            age: age,
            mobile: mobile,
            gender: gender,
            whoYouAre: whoYouAre, // ✅ Passed correctly
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDay = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text("Hi $name, Happy $currentDay!"),
        backgroundColor: const Color(0xFF5A9BD8),
        centerTitle: true,
      ),
      body: Center(
        child: _selectedIndex == 0
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Your Results", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text("Pending Works", style: TextStyle(fontSize: 20)),
          ],
        )
            : const Text(
          "Notifications will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notify'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
