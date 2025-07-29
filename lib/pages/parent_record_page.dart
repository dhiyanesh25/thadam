import 'package:flutter/material.dart';

class ParentRecordPage extends StatelessWidget {
  final List<Map<String, dynamic>> studentRecords;
  final String studentName;

  const ParentRecordPage({
    super.key,
    required this.studentRecords,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records for $studentName'),
        backgroundColor: const Color(0xFF5A9BD8),
      ),
      body: studentRecords.isEmpty
          ? const Center(child: Text("No records found for this student."))
          : ListView.builder(
        itemCount: studentRecords.length,
        itemBuilder: (context, index) {
          final student = studentRecords[index];

          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                student['name'] ?? 'Unnamed',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Disability: ${student['disability'] ?? 'Not available'}"),
                  Text("Gender: ${student['gender'] ?? 'Not available'}"),
                  Text("Age: ${student['age'] ?? 'Not available'}"),
                  const SizedBox(height: 4),
                  if (student['records'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        (student['records'] as List).length,
                            (i) {
                          final record = student['records'][i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "📌 ${record['areaOfSupport'] ?? 'Area'} | "
                                  "Challenge: ${record['challenge'] ?? 'None'} | "
                                  "Rating: ${record['finalRating'] ?? '-'}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
