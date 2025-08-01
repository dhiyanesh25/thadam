# 🌱 Thadam – Empowering Inclusive Education

Thadam is a Flutter-based mobile application designed to support Special Educators, Teachers, Parents, and Therapists in monitoring and improving student development through a structured recording and rating system. The app uses Firebase for authentication, storage, and secure data handling.

---

## ✨ Features

### 🔐 Authentication & User Roles
- Mobile number-based login (formatted as email: `number@gmail.com`)
- Role-based registration: Special Educator, Teacher, Parent, Therapist
- "Remember Me" login using SharedPreferences
- Role-based redirection to appropriate dashboards after login/register
- Firebase password reset functionality

### 📋 Student Record Management
- Special Educators/Teachers can:
  - Add student profiles: name, age, gender, disability
  - Add and view detailed records for each student
  - Rate students on various areas of support with challenges observed
  - Generate PDFs of records and share/save them locally
  - Filter and sort student records by name, age, gender, or rating

- Parents/Therapists can:
  - View only the students registered under their care
  - Access filtered records entered by Special Educators
  - View final ratings and challenges

### 📂 Record Structure
- Areas of Support (AF, CS, ER, SR, IH, TIC, TA, SI, CA, SBA)
- Dynamic challenge dropdowns based on selected area
- Initial & final 5-star rating system
- Color-coded record cards based on rating (green/yellow/orange)
- Custom date entry for records
- Multiple entries allowed per student

### 📤 Share & Download
- Share student records as downloadable PDF files
- PDF saved in device's Downloads folder automatically

---

## 📁 Project Structure

```plaintext
lib/
├── main.dart
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── dashboard_page.dart
│   ├── parent_dashboard_page.dart
│   ├── record_page.dart
│   ├── parent_record_page.dart
│   ├── student_detail_page.dart
│   └── profile_page.dart
├── models/
│   └── student_model.dart
├── services/
│   └── firebase_service.dart
├── widgets/
│   └── custom_dropdown.dart
