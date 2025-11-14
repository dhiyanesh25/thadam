import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'parent_record_page.dart';
import 'profile_page.dart';

class ParentDashboardPage extends StatefulWidget {
  final String name;
  final String age;
  final String mobile; // Used to link students
  final String gender;
  final String whoYouAre;

  const ParentDashboardPage({
    super.key,
    required this.name,
    required this.age,
    required this.mobile,
    required this.gender,
    required this.whoYouAre,
  });

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Restrict access to only parents
    if (widget.whoYouAre != 'Parent') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied: Only parents can view this page'),
          ),
        );
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParentRecordPage(
            parentPhone: widget.mobile, // FIXED: Changed to parentPhone
            userRole: widget.whoYouAre,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            name: widget.name,
            age: widget.age,
            mobile: widget.mobile,
            gender: widget.gender,
            whoYouAre: widget.whoYouAre,
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
        title: Text("Hi ${widget.name}, Happy $currentDay!"),
        backgroundColor: const Color(0xFF5A9BD8),
        centerTitle: true,
      ),
      body: Center(
        child: _selectedIndex == 0
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Your Results", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text(
              "You are viewing your child's progress.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text("Pending Works", style: TextStyle(fontSize: 20)),
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
        selectedItemColor: const Color(0xFF5A9BD8),
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
