// lib/pages/record_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'student_details_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';

// NEW imports
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'tutorial_steps.dart';

class RecordPage extends StatefulWidget {
  final String userRole;

  const RecordPage({super.key, required this.userRole});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool ascending = true;
  String selectedStatus = "Active";
  Map<String, dynamic>? _deletedStudent;
  String? _deletedDocId;

  // 🔹 Chatbot UI Controller
  bool _isChatbotOpen = false;

  // 🔹 ApiService instance
  late ApiService api;

  @override
  void initState() {
    super.initState();
    // Set your backend URL here (change for emulator/device/production)
    api = ApiService("http://10.0.2.2:8000");
  }

  // 🔹 Function to show chatbot popup (updated to use shared tutorialSteps & ApiService)
  void _openChatbot() {
    setState(() => _isChatbotOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isTutorialSelected = false;
            bool isUploadSelected = false;
            bool loading = false;

            // modal scroll controller so we can auto-scroll to new messages
            final ScrollController modalScrollController = ScrollController();

            // local message list inside modal
            final List<Map<String, dynamic>> localMessages = [
              {
                'text': "Hi! I'm your assistant 👋\nPlease choose an option:",
                'isUser': false,
                'actions': [
                  {'id': 'tutorial', 'label': 'Tutorial Mode'},
                  {'id': 'upload', 'label': 'Upload Data'},
                ],
                'actionsUsed': false,
              }
            ];

            void pushBotMessage(String text, {List<Map<String, String>>? actions}) {
              localMessages.add({
                'text': text,
                'isUser': false,
                'actions': actions ?? [],
                'actionsUsed': false,
              });
              setSheetState(() {});
              // scroll to bottom after render
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (modalScrollController.hasClients) {
                  modalScrollController.animateTo(
                    modalScrollController.position.maxScrollExtent + 120,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            void pushUserMessage(String text) {
              localMessages.add({'text': text, 'isUser': true});
              setSheetState(() {});
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (modalScrollController.hasClients) {
                  modalScrollController.animateTo(
                    modalScrollController.position.maxScrollExtent + 120,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            Future<void> handleTopAction(String id) async {
              setSheetState(() {
                localMessages[0]['actionsUsed'] = true; // hide initial buttons
                if (id == 'tutorial') {
                  isTutorialSelected = true;
                  isUploadSelected = false;
                } else {
                  isUploadSelected = true;
                  isTutorialSelected = false;
                }
              });

              if (id == 'tutorial') {
                final actions = List.generate(
                  tutorialSteps.length,
                      (i) => {'id': 'step_$i', 'label': tutorialSteps[i]},
                );
                pushBotMessage("Follow these steps to record a student manually:", actions: actions);
              } else {
                pushBotMessage("You can upload an Excel/CSV file to add multiple students at once.");
              }
            }

            Future<void> handleTutorialStep(int stepIndex) async {
              final stepText = tutorialSteps[stepIndex];
              pushUserMessage(stepText);
              setSheetState(() => loading = true);
              try {
                final resp = await api.sendMessage(stepText);
                pushBotMessage(resp);
              } catch (e) {
                pushBotMessage("Error: $e");
              } finally {
                setSheetState(() => loading = false);
              }
            }

            Future<void> handleUploadFlow() async {
              pushUserMessage("Upload selected");
              setSheetState(() => loading = true);
              try {
                final pf = await FilePicker.platform.pickFiles(
                    type: FileType.custom, allowedExtensions: ['xls', 'xlsx', 'csv']);
                if (pf == null) {
                  pushBotMessage("Upload cancelled.");
                  setSheetState(() => loading = false);
                  return;
                }
                final file = File(pf.files.single.path!);
                pushBotMessage("Uploading ${pf.files.single.name}...");
                final res = await api.uploadFile(file);
                pushBotMessage("Upload complete. Response: ${res.toString()}");
                // If backend returns file id and you'd like to start a chat about it:
                // if (res.containsKey('file_id')) {
                //   final reply = await api.sendMessage('File uploaded', fileId: res['file_id']);
                //   pushBotMessage(reply);
                // }
              } catch (e) {
                pushBotMessage("Upload failed: $e");
              } finally {
                setSheetState(() => loading = false);
              }
            }

            Widget buildMessage(Map<String, dynamic> msg) {
              final isUser = msg['isUser'] == true;
              final text = msg['text'] as String;
              final actions = msg['actions'] as List? ?? [];
              final actionsUsed = msg['actionsUsed'] == true;

              if (isUser) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.lightGreen.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(text),
                  ),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(text),
                    ),
                    if (actions.isNotEmpty && !actionsUsed)
                      Wrap(
                        spacing: 8,
                        children: actions.map<Widget>((a) {
                          final id = a['id'] as String;
                          final label = a['label'] as String;
                          return OutlinedButton(
                            onPressed: () async {
                              if (id == 'tutorial') {
                                await handleTopAction('tutorial');
                              } else if (id == 'upload') {
                                await handleTopAction('upload');
                              } else if (id.startsWith('step_')) {
                                final idx = int.parse(id.split('_').last);
                                await handleTutorialStep(idx);
                              }
                            },
                            child: Text(label),
                          );
                        }).toList(),
                      ),
                  ],
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Thadam Assistant",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                localMessages.clear();
                                localMessages.add({
                                  'text': "Hi! I'm your assistant 👋\nPlease choose an option:",
                                  'isUser': false,
                                  'actions': [
                                    {'id': 'tutorial', 'label': 'Tutorial Mode'},
                                    {'id': 'upload', 'label': 'Upload Data'},
                                  ],
                                  'actionsUsed': false,
                                });
                                setSheetState(() {});
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (modalScrollController.hasClients) {
                                    modalScrollController.jumpTo(0);
                                  }
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("New"),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                // optional: reset scroll before closing
                                if (modalScrollController.hasClients) {
                                  modalScrollController.jumpTo(0);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(),

                    // ListView with controller so we can auto-scroll when messages are added
                    Expanded(
                      child: ListView.builder(
                        controller: modalScrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: localMessages.length,
                        itemBuilder: (ctx, idx) => buildMessage(localMessages[idx]),
                      ),
                    ),

                    if (loading) const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isUploadSelected)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text("Pick & Upload File"),
                            onPressed: handleUploadFlow,
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            // Back behavior: reset modal view by popping bot messages after initial
                            if (localMessages.length > 1) {
                              localMessages.removeRange(1, localMessages.length);
                              setSheetState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (modalScrollController.hasClients) {
                                  modalScrollController.animateTo(
                                    modalScrollController.position.maxScrollExtent + 120,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Back"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _isChatbotOpen = false);
    });
  }

  Future<void> _addStudentDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '', age = '', gender = '', disability = '', parentPhone = '';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Student Profile"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Name"),
                          onChanged: (val) => name = val,
                          validator: (val) => val!.isEmpty ? 'Enter name' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Age"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => age = val,
                          validator: (val) => val!.isEmpty ? 'Enter age' : null,
                        ),
                        DropdownButtonFormField(
                          value: gender.isEmpty ? null : gender,
                          items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => gender = val!,
                          decoration: const InputDecoration(labelText: "Gender"),
                          validator: (val) => val == null ? 'Select gender' : null,
                        ),
                        DropdownButtonFormField(
                          value: disability.isEmpty ? null : disability,
                          items: [
                            'Hearing Impairment',
                            'Visual Impairment',
                            'Locomotor Disability',
                            'Intellectual Disability',
                            'Autism Spectrum Disorder',
                            'Multiple Disability'
                          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => disability = val!,
                          decoration: const InputDecoration(labelText: "Disability"),
                          validator: (val) => val == null ? 'Select disability' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Parent Phone Number"),
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => parentPhone = val,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Enter parent phone number';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                              return 'Enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final currentUserId = auth.currentUser!.uid;
                      try {
                        await firestore.collection('students').add({
                          'name': name,
                          'age': age,
                          'gender': gender,
                          'disability': disability,
                          'parentPhone': parentPhone,
                          'createdAt': Timestamp.fromDate(selectedDate),
                          'createdBy': currentUserId,
                          'role': widget.userRole,
                          'status': 'Active',
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Student added successfully")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add student: $e")),
                        );
                      }
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 PDF Generate & Share Function
  Future<void> _generateAndSharePdf(Map<String, dynamic> studentData) async {
    try {
      await Permission.storage.request();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Student Report - Thadam", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Generated on: ${DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}", style: pw.TextStyle(fontSize: 12)),
              pw.Divider(),
              ...studentData.entries.map(
                    (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text("${e.key}: ${e.value ?? ''}", style: const pw.TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );

      final downloads = Directory('/storage/emulated/0/Download');
      final filePath = '${downloads.path}/${studentData['name'] ?? 'student'}_report.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(bytes: await pdf.save(), filename: '${studentData['name'] ?? 'student'}_report.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved & ready to share: $filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.currentUser!;
    final currentUserId = currentUser.uid;

    Query query = firestore.collection('students');
    if (widget.userRole == 'parent') {
      String parentPhone = currentUser.email!.split('@').first;
      query = query.where('parentPhone', isEqualTo: parentPhone).where('status', isEqualTo: 'Active');
    } else {
      query = query.where('createdBy', isEqualTo: currentUserId).where('status', isEqualTo: selectedStatus);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profiles"),
        backgroundColor: const Color(0xFF5A9BD8),
        actions: [
          if (widget.userRole != 'parent')
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStatus,
                items: ['Active', 'Inactive'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedStatus = val);
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              setState(() {
                ascending = !ascending;
              });
            },
            tooltip: "Sort by Name",
          ),
          if (widget.userRole != 'parent')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addStudentDialog,
            ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No student records found."));
              }

              List<DocumentSnapshot> docs = snapshot.data!.docs;
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                return ascending ? (aData['name'] ?? '').compareTo(bData['name'] ?? '') : (bData['name'] ?? '').compareTo(aData['name'] ?? '');
              });

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  final status = data['status'] ?? 'Active';

                  return ListTile(
                    leading: Icon(Icons.circle, color: status == "Active" ? Colors.green : Colors.grey, size: 16),
                    title: Text('${data['name'] ?? ''}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Age: ${data['age'] ?? 'N/A'}"),
                        Text("Gender: ${data['gender'] ?? 'N/A'}"),
                        Text("Disability: ${data['disability'] ?? 'N/A'}"),
                        Text("Status: $status"),
                      ],
                    ),
                    trailing: widget.userRole != 'parent'
                        ? IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), onPressed: () => _generateAndSharePdf(data))
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDetailPage(studentId: id, studentName: '${data['name'] ?? ''}', userRole: widget.userRole),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          if (widget.userRole != 'parent')
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.blueAccent,
                onPressed: _openChatbot,
                tooltip: "Open Chatbot",
                child: const Icon(Icons.chat),
              ),
            ),
        ],
      ),
    );
  }
}
