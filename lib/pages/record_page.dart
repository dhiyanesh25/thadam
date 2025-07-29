import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'student_details_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool sortByName = true;
  bool ascending = true;
  String filterBy = '';
  String filterValue = '';

  Future<void> _addStudentDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '', age = '', gender = '', disability = '';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Name"),
                    onSaved: (val) => name = val!,
                    validator: (val) => val!.isEmpty ? 'Enter name' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => age = val!,
                    validator: (val) => val!.isEmpty ? 'Enter age' : null,
                  ),
                  DropdownButtonFormField(
                    value: gender.isEmpty ? null : gender,
                    items: ['Male', 'Female', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
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
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                await firestore.collection('students').add({
                  'name': name,
                  'age': age,
                  'gender': gender,
                  'disability': disability,
                  'createdAt': selectedDate,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() async {
    final TextEditingController valueController = TextEditingController();
    String? selectedField;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Students"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedField,
              items: ['Name', 'Age', 'Gender']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => selectedField = val),
              decoration: const InputDecoration(labelText: "Filter By"),
            ),
            TextFormField(
              controller: valueController,
              decoration: const InputDecoration(labelText: "Value"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                filterBy = '';
                filterValue = '';
              });
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                filterBy = selectedField?.toLowerCase() ?? '';
                filterValue = valueController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePdf(Map<String, dynamic> studentData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Student Profile',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Name: ${studentData['name'] ?? 'N/A'}'),
            pw.Text('Age: ${studentData['age'] ?? 'N/A'}'),
            pw.Text('Gender: ${studentData['gender'] ?? 'N/A'}'),
            pw.Text('Disability: ${studentData['disability'] ?? 'N/A'}'),
            pw.Text('Created At: ${studentData['createdAt'] != null ? DateFormat('yyyy-MM-dd').format((studentData['createdAt'] as Timestamp).toDate()) : 'N/A'}'),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    // Ask permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permission denied")));
      return;
    }

    final dir = await getExternalStorageDirectory();
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final filePath = '${downloadsDir.path}/${studentData['name']}_Profile.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF saved to $filePath")));

    // Optional: Share the file
    await Printing.sharePdf(bytes: pdfBytes, filename: '${studentData['name']}_Profile.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profiles"),
        backgroundColor: const Color(0xFF5A9BD8),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              setState(() {
                if (sortByName) {
                  sortByName = false;
                } else {
                  ascending = !ascending;
                  sortByName = true;
                }
              });
            },
            tooltip: "Sort by ${sortByName ? 'Date' : 'Name'}",
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: "Filter",
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addStudentDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<DocumentSnapshot> docs = snapshot.data!.docs;

          if (filterBy.isNotEmpty && filterValue.isNotEmpty) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final value = data[filterBy]?.toString().toLowerCase();
              return value != null && value.contains(filterValue.toLowerCase());
            }).toList();
          }

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            if (sortByName) {
              return ascending
                  ? (aData['name'] ?? '').compareTo(bData['name'] ?? '')
                  : (bData['name'] ?? '').compareTo(aData['name'] ?? '');
            } else {
              final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
            }
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Age: ${data['age'] ?? 'N/A'}"),
                    Text("Gender: ${data['gender'] ?? 'N/A'}"),
                    Text("Disability: ${data['disability'] ?? 'N/A'}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blueAccent),
                      onPressed: () => _generateAndSharePdf(data),
                      tooltip: 'Share PDF',
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetailPage(
                        studentId: id,
                        studentName: data['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
