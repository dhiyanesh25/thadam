import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_details_page.dart';

class ParentRecordPage extends StatefulWidget {
  final String parentPhone; // Parent's phone number from registration/login
  final String userRole; // Should be "Parent"

  const ParentRecordPage({
    super.key,
    required this.parentPhone,
    required this.userRole,
  });

  @override
  State<ParentRecordPage> createState() => _ParentRecordPageState();
}

class _ParentRecordPageState extends State<ParentRecordPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DocumentSnapshot>> _fetchStudentRecords() async {
    if (widget.userRole != "Parent") return [];
    final snapshot = await _firestore
        .collection('students')
        .where('parentPhone', isEqualTo: widget.parentPhone)
        .get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchStudentRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (widget.userRole != "Parent") {
          return const Scaffold(
            body: Center(
              child: Text(
                "Access Denied. Only parents can view this page.",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          );
        }

        final students = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Child Records'),
            backgroundColor: const Color(0xFF5A9BD8),
          ),
          body: students.isEmpty
              ? const Center(
            child: Text(
              "No student records found for this parent.",
              style: TextStyle(fontSize: 16),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentData =
              students[index].data() as Map<String, dynamic>;
              final studentId = students[index].id;

              // Updated: Fetch correct student name
              final name = studentData['name'] ??
                  studentData['studentName'] ??
                  'Unnamed';

              final disability = studentData['disability'] ?? 'Not available';
              final gender = studentData['gender'] ?? 'Not available';
              final age = studentData['age']?.toString() ?? 'Not available';
              final records =
                  (studentData['records'] as List<dynamic>?) ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Disability: $disability"),
                      Text("Gender: $gender"),
                      Text("Age: $age"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentDetailPage(
                                studentId: studentId,
                                studentName: name,
                                userRole: "Parent",
                              ),
                            ),
                          );
                        },
                        child: const Text("View Full Details"),
                      ),
                      const SizedBox(height: 10),
                      if (records.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Progress Records:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...records.map((record) {
                              final area = record['areaOfSupport'] ?? 'N/A';
                              final challenge = record['challenge'] ?? 'N/A';
                              final rating =
                                  (record['finalRating'] as int?) ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "📌 Area: $area",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Challenge: $challenge"),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            "No progress records available.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
