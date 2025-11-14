import 'package:flutter/material.dart';
import 'chatbot_page.dart';

class ChatbotWidget extends StatelessWidget {
  const ChatbotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotPage()),
          );
        },
      ),
    );
  }
}
