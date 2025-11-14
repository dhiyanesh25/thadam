import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String userRole; // Added role

  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.userRole,
  });

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String selectedSort = 'date';

  final Map<String, List<String>> challengeOptions = {
    'Attention and Focus (AF)': [
      'Easily distracted',
      'Moderately distracted',
      'Misses instructions',
      'No Challenges'
    ],
    'Communication Support (CS)': [
      'Non Verbal',
      'Verbal',
      'Delayed or Scattered Expression',
      'Misunderstood',
      'No Challenges'
    ],
    'Emotional Regulation (ER)': [
      'Mood Swings',
      'Frustration',
      'Shutdowns',
      'No Challenges'
    ],
    'Sensory Regulation (SR)': [
      'Over Sensitive to Noise',
      'Under Sensitive to Noise',
      'Over Sensitive to Light',
      'Under Sensitive to Light',
      'Over Sensitive to Touch',
      'Under Sensitive to Touch',
      'Over Sensitive to Smell',
      'Under Sensitive to Smell',
      'Over Sensitive to Taste',
      'Under Sensitive to Taste',
      'Regular - Noise',
      'Regular - Light',
      'Regular - Touch',
      'Regular - Smell',
      'Regular - Taste',
      'No Challenges',
      'Other:'
    ],
    'Impulsivity & Hyperactivity (IH)': [
      'Interrupts Often',
      'Interrupts Mediatory',
      'Touches everything',
      "Can't sit still",
      "Can't stand still",
      'Circles around',
      'Keeps running',
      'Bangs objects',
      'Bangs Body parts',
      'Bangs Others',
      'No Challenges'
    ],
    'Task Initiation & Completion (TIC)': [
      'Avoids tasks',
      'Forgets steps',
      'Overwhelmed',
      'No Challenges'
    ],
    'Transition between Activities (TA)': [
      'Difficulty shifting focus',
      'Meltdowns',
      'Refusal',
      'No Challenges'
    ],
    'Social Interactions (SI)': [
      'Misreads social cues',
      'Impulsive',
      'Intense emotions',
      'Not interested',
      'No Challenges'
    ],
    'Collaboration with Adults (CA)': [
      'Mistrust',
      'Meltdowns during Adult led Tasks',
      'No Challenges'
    ],
    'Strength Based Appreciation (SBA)': [
      'Fine Motor - One Hand',
      'Fine Motor - Both Hands',
      'Gross Motor - One Leg',
      'Gross Motor - Both Legs',
      'Auditory',
      'Visual',
      'Memory',
      'Organisation',
      'Comprehension',
      'Social'
    ],
  };

  String? selectedArea;
  String? selectedChallenge;

  bool get isParent => widget.userRole.toLowerCase() == 'parent';

  Future<void> _addRecordDialog() async {
    if (isParent) return; // Parents cannot add records

    final _formKey = GlobalKey<FormState>();
    double initialRating = 1;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Record"),
        content: Form(
          key: _formKey,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedArea,
                    items: challengeOptions.keys
                        .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedArea = val;
                        selectedChallenge = null;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Area of Support'),
                    validator: (val) => val == null ? 'Select area' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedChallenge,
                    items: (selectedArea != null
                        ? challengeOptions[selectedArea] ?? []
                        : [])
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() => selectedChallenge = val);
                    },
                    decoration: const InputDecoration(labelText: 'Challenges Observed'),
                    validator: (val) => val == null ? 'Select challenge' : null,
                  ),
                  const SizedBox(height: 10),
                  const Text("Initial Rating"),
                  RatingBar.builder(
                    initialRating: 1,
                    minRating: 1,
                    maxRating: 5,
                    allowHalfRating: false,
                    itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => initialRating = rating,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await firestore
                    .collection('students')
                    .doc(widget.studentId)
                    .collection('records')
                    .add({
                  'areaOfSupport': selectedArea,
                  'challenge': selectedChallenge,
                  'initialRating': initialRating.toInt(),
                  'finalRating': 0,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFinalRating(String docId) async {
    if (isParent) return; // Parents cannot update ratings

    double finalRating = 1;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Final Rating"),
        content: RatingBar.builder(
          initialRating: 1,
          minRating: 1,
          maxRating: 5,
          allowHalfRating: false,
          itemBuilder: (context, _) =>
          const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) => finalRating = rating,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () async {
              await firestore
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('records')
                  .doc(docId)
                  .update({
                'finalRating': finalRating.toInt(),
                'finalRatingDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        backgroundColor: const Color(0xFF5A9BD8),
        actions: [
          if (!isParent) // Only show Add button for non-parents
            IconButton(icon: const Icon(Icons.add), onPressed: _addRecordDialog),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.sort, size: 18),
            label: const Text("Sort"),
            onPressed: () async {
              final value = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text("Sort By"),
                  children: [
                    SimpleDialogOption(
                      child: const Text("Date"),
                      onPressed: () => Navigator.pop(context, 'date'),
                    ),
                    SimpleDialogOption(
                      child: const Text("Initial Rating"),
                      onPressed: () => Navigator.pop(context, 'initialRating'),
                    ),
                    SimpleDialogOption(
                      child: const Text("Final Rating"),
                      onPressed: () => Navigator.pop(context, 'finalRating'),
                    ),
                  ],
                ),
              );
              if (value != null) setState(() => selectedSort = value);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('students')
            .doc(widget.studentId)
            .collection('records')
            .orderBy(selectedSort, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final records = snapshot.data!.docs;

          if (records.isEmpty) return const Center(child: Text("No records"));

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (_, index) {
              final data = records[index].data() as Map<String, dynamic>;
              final finalRating = data['finalRating'] ?? 0;

              final cardColor = finalRating == 5
                  ? Colors.green[100]
                  : finalRating >= 3
                  ? Colors.orange[100]
                  : null;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['areaOfSupport'] ?? 'No Area'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Challenge: ${data['challenge'] ?? ''}"),
                      Text("Initial Rating: ${data['initialRating']}"),
                      Text("Final Rating: ${finalRating == 0 ? 'Not Set' : finalRating}"),
                      Text("Date: ${data['date'] ?? ''}"),
                    ],
                  ),
                  trailing: !isParent
                      ? IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () => _updateFinalRating(records[index].id),
                  )
                      : null, // Parents cannot update
                ),
              );
            },
          );
        },
      ),
    );
  }
}
