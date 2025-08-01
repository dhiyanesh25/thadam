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

          final name = student['name'] ?? 'Unnamed';
          final disability = student['disability'] ?? 'Not available';
          final gender = student['gender'] ?? 'Not available';
          final age = student['age'] ?? 'Not available';
          final records = student['records'] as List<dynamic>? ?? [];

          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Disability: $disability"),
                  Text("Gender: $gender"),
                  Text("Age: $age"),
                  const SizedBox(height: 12),
                  if (records.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Progress Records:",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...records.map((record) {
                          final area = record['areaOfSupport'] ?? 'N/A';
                          final challenge =
                              record['challenge'] ?? 'N/A';
                          final rating = record['finalRating'] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueGrey),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text("📌 Area: $area",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text("Challenge: $challenge"),
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
                          );
                        }).toList(),
                      ],
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
