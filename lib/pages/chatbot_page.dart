// lib/pages/chatbot_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'chat_message.dart';
import 'chat_message_bubble.dart';
import 'chatbot_service.dart';
import 'package:file_picker/file_picker.dart';
import 'tutorial_steps.dart'; // ensure this file exists at lib/pages/tutorial_steps.dart

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // UI-mode flags for quick-reply flows
  bool _showQuickReplies = true; // initial quick replies (Tutorial / Upload)
  bool _tutorialModeActive = false; // when true show tutorial step buttons

  @override
  void initState() {
    super.initState();
    // initial assistant greeting
    _messages.add(ChatMessage(
      text: "Hi! I'm your assistant 👋\nChoose an option below to get started.",
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    // Add user message and clear input immediately for snappy UI
    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _controller.clear();
      _isLoading = true;
      // after user sends a typed message, hide quick replies
      _showQuickReplies = false;
      _tutorialModeActive = false;
    });
    _scrollToBottom();

    try {
      final reply = await ChatbotService.sendMessage(trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      });
      _scrollToBottom();
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // invoked when a quick-reply button (Tutorial Mode / Upload Data) is tapped
  void _handleQuickReply(String id) {
    if (_isLoading) return;
    if (id == 'tutorial') {
      setState(() {
        _tutorialModeActive = true;
        _showQuickReplies = false;
      });
      // push a bot hint message
      setState(() {
        _messages.add(ChatMessage(text: "Opening Tutorial Mode — pick a step below.", isUser: false));
      });
      _scrollToBottom();
    } else if (id == 'upload') {
      // open upload flow directly
      _uploadFile();
    }
  }

  // When user picks one of the tutorial steps
  Future<void> _handleTutorialStep(int index) async {
    if (_isLoading) return;
    final stepText = tutorialSteps[index];
    // Add user message (selected step)
    setState(() {
      _messages.add(ChatMessage(text: stepText, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await ChatbotService.sendMessage(stepText);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: "Assistant error: $e", isUser: false));
      });
      _scrollToBottom();
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    if (_isLoading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() {
      _messages.add(ChatMessage(text: "Uploading file: ${file.path.split('/').last}", isUser: true));
      _isLoading = true;
      _showQuickReplies = false;
      _tutorialModeActive = false;
    });
    _scrollToBottom();

    try {
      final Map<String, dynamic> resp = await ChatbotService.uploadFile(file);
      final msg = resp['message'] ??
          (resp['result'] != null ? resp['result'].toString() : 'Uploaded');
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: msg.toString(), isUser: false));
      });
      _scrollToBottom();

      // Optional: if backend returns a file_id and you want to start a chat referencing it:
      // if (resp.containsKey('file_id')) {
      //   final fileId = resp['file_id'];
      //   final followUp = await ChatbotService.sendMessage("File uploaded", fileId: fileId);
      //   setState(() => _messages.add(ChatMessage(text: followUp, isUser: false)));
      //   _scrollToBottom();
      // }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: "File upload failed: $e", isUser: false));
      });
      _scrollToBottom();
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Build tutorial step buttons
  Widget _buildTutorialButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tutorial Steps", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tutorialSteps.length, (index) {
              final step = tutorialSteps[index];
              return OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _handleTutorialStep(index),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 140),
                  child: Text(
                    "Step ${index + 1}: ${step.replaceFirst(RegExp(r'^Step \d+:\s*'), '')}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Divider(),
        ],
      ),
    );
  }

  // Build quick-reply buttons (Tutorial Mode / Upload Data)
  Widget _buildQuickReplies() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Wrap(
        spacing: 8,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.school),
            label: const Text("Tutorial Mode"),
            onPressed: () => _handleQuickReply('tutorial'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Data"),
            onPressed: () => _handleQuickReply('upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thadam Chatbot Assistant"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_tutorialModeActive ? 1 : 0),
              itemBuilder: (context, index) {
                // If tutorial mode active, show tutorial buttons anchored at the bottom of list
                if (_tutorialModeActive && index == _messages.length) {
                  return _buildTutorialButtons();
                }
                return ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),

          if (_showQuickReplies && _messages.isNotEmpty) _buildQuickReplies(),

          if (_isLoading) const LinearProgressIndicator(),

          // Input row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _isLoading ? null : _uploadFile,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _sendMessage(value),
                  decoration: const InputDecoration(hintText: "Type your message..."),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
