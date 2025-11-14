import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_page.dart';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMobile = prefs.getString('savedMobile') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';

    if (savedMobile.isNotEmpty && savedPassword.isNotEmpty) {
      setState(() {
        _mobileController.text = savedMobile;
        _passwordController.text = savedPassword;
        rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('savedMobile', _mobileController.text.trim());
      await prefs.setString('savedPassword', _passwordController.text.trim());
    } else {
      await prefs.remove('savedMobile');
      await prefs.remove('savedPassword');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A9BD8),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Welcome to Thadam',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Let's get Started with it!",
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 30),

              const Text('Mobile number'),
              TextFormField(
                controller: _mobileController,
                decoration: _inputDecoration(),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your mobile number';
                  }
                  if (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Mobile number must be exactly 10 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value!;
                      });
                    },
                  ),
                  const Text('Remember me?'),
                ],
              ),

              Center(
                child: ElevatedButton(
                  onPressed: _loginUser,
                  style: _elevatedBtnStyle(),
                  child: const Text('Log In'),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(children: const [
                Expanded(child: Divider(color: Colors.white)),
                Text(" or ", style: TextStyle(color: Colors.white)),
                Expanded(child: Divider(color: Colors.white)),
              ]),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text(
                    'New User? Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      final mobile = _mobileController.text.trim();
      final email = "$mobile@gmail.com"; // login using email+password
      final password = _passwordController.text.trim();

      try {
        // FirebaseAuth Login
        await _auth.signInWithEmailAndPassword(email: email, password: password);

        // Get the logged-in user's UID
        final user = _auth.currentUser;
        if (user == null) {
          _showSnackBar('Authentication failed. Please try again.');
          return;
        }

        // Firestore lookup using UID
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          _showSnackBar('User profile not found in database.');
          return;
        }

        final data = doc.data()!;
        final name = data['name'];
        final age = data['age'];
        final gender = data['gender'];
        final userType = data['userType'];

        await _saveCredentials();

        if (userType == "Parent") {
          // For parents, we pass their mobile number directly to parent dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentDashboardPage(
                name: name,
                age: age,
                mobile: mobile, // Parent's phone
                gender: gender,
                whoYouAre: userType,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                name: name,
                age: age,
                mobile: mobile,
                gender: gender,
                whoYouAre: userType,
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _showSnackBar('User not found. Redirecting to registration...');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          );
        } else if (e.code == 'wrong-password') {
          _showSnackBar('Incorrect password. Try again.');
        } else {
          _showSnackBar('Login failed: ${e.message}');
        }
      } catch (e) {
        _showSnackBar('An error occurred. Try again.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade300,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );

  ButtonStyle _elevatedBtnStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF0A2D63),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
  );
}
