import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _studentNameController = TextEditingController();

  String? _selectedGender;
  String? _selectedUserType;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color blueColor = const Color(0xFF5A9BD8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blueColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Register',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),

              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 12),

              _buildTextField(_ageController, 'Age',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),

              _buildTextField(
                _mobileController,
                'Mobile Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter mobile number';
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                _emailController,
                'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _dropdownField(
                label: "Gender",
                value: _selectedGender,
                items: ['Male', 'Female', 'Other'],
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 12),

              _dropdownField(
                label: "Who Are You",
                value: _selectedUserType,
                items: ['Special Educator', 'Teacher', 'Parent', 'Therapist'],
                onChanged: (val) => setState(() => _selectedUserType = val),
              ),
              const SizedBox(height: 12),

              if (_selectedUserType == 'Parent' || _selectedUserType == 'Therapist') ...[
                _buildTextField(_studentNameController, 'Student Name'),
                const SizedBox(height: 12),
              ],

              _buildTextField(
                _passwordController,
                'Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter password';
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value)) {
                    return 'Min 8 chars, 1 capital, 1 number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                _confirmPasswordController,
                'Confirm Password',
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2D63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Register'),
              ),
              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  child: const Text("Already registered? Login",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator ??
              (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text("Select $label"),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null || _selectedUserType == null) {
        _showSnackBar("Please select both gender and role.");
        return;
      }

      final name = _nameController.text.trim();
      final age = _ageController.text.trim();
      final mobile = _mobileController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final studentName = _studentNameController.text.trim();

      final isParentOrTherapist =
          _selectedUserType == 'Parent' || _selectedUserType == 'Therapist';

      try {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);

        final userData = {
          'name': name,
          'age': age,
          'gender': _selectedGender,
          'userType': _selectedUserType,
          'mobile': mobile,
          'email': email,
          if (isParentOrTherapist) 'studentName': studentName,
        };

        await _firestore.collection('users').doc(mobile).set(userData);

        if (isParentOrTherapist) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ParentDashboardPage(
                name: name,
                age: age,
                mobile: mobile,
                gender: _selectedGender!,
                whoYouAre: _selectedUserType!,
                studentName: studentName,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardPage(
                name: name,
                age: age,
                mobile: mobile,
                gender: _selectedGender!,
                whoYouAre: _selectedUserType!,
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? "Authentication error");
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
