// lib/pages/tutorial_steps.dart
//
// This file defines the tutorial flow steps for the Thadam Assistant chatbot.
// You can import this in both record_page.dart and chatbot files to keep
// tutorial content consistent across your app.

/// A list of tutorial steps that explain how to record a student manually.
/// These steps will be shown inside the chatbot when the user selects "Tutorial Mode".
const List<String> tutorialSteps = [
  "Step 1: Click the '+' button on the top right to add a new student.",
  "Step 2: Fill in all required details such as name, age, gender, disability, etc.",
  "Step 3: Press 'Add' to save the student profile to the database.",
  "Step 4: You can view, update, or generate PDFs anytime from the student list below.",
  "Step 5: Use the Share icon next to each student to generate and share a report PDF."
];

/// Optionally, you can provide short summaries for chatbot quick replies.
/// This helps if you want the chatbot to explain each step in a separate message.
const Map<String, String> tutorialExplanations = {
  "Step 1: Click the '+' button on the top right to add a new student.":
  "To start adding a new student, press the '+' icon on the top right corner of the Student Profiles page.",
  "Step 2: Fill in all required details such as name, age, gender, disability, etc.":
  "A form will appear. Enter all details such as name, age, gender, and select the type of disability.",
  "Step 3: Press 'Add' to save the student profile to the database.":
  "After completing the form, tap 'Add' to save the student record to Firebase.",
  "Step 4: You can view, update, or generate PDFs anytime from the student list below.":
  "All saved students appear in the list. You can tap on a student to view or update their information.",
  "Step 5: Use the Share icon next to each student to generate and share a report PDF.":
  "To create a PDF report, tap the share icon. The app will generate a PDF and open sharing options."
};
