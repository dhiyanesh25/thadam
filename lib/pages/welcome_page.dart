import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A9BD8),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: MediaQuery.of(context).size.height * 0.35, // 35% of screen height
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thadam',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.8 * 255).toInt()),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 4))],
              ),
              child: const Text(
                'Tracking every step, ''celebrating every win',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2D63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
