import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import 'dashboard_page.dart';
import 'parent_dashboard_page.dart';

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
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
              const Text("Let's get Started with it!",
                  style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 30),

              const Text('Mobile number'),
              TextFormField(
                controller: _mobileController,
                decoration: inputDecoration(),
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
                decoration: inputDecoration(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  if (!RegExp(r'^(?=.*[A-Z]).{6,}$').hasMatch(value)) {
                    return 'Password must have at least 1 uppercase letter and 6+ characters';
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

              const SizedBox(height: 20),

              Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                  onPressed: _loginUser,
                  style: elevatedBtnStyle(),
                  child: const Text('Log In'),
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
                  child: const Text('New User? Register',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
      final mobile = _mobileController.text;
      final email = "$mobile@gmail.com";
      final password = _passwordController.text;

      setState(() => isLoading = true);

      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        print("Firebase login successful for $email");

        final doc = await _firestore.collection('users').doc(mobile).get();

        if (!doc.exists) {
          _showSnackBar('User profile not found in database.');
          print("Firestore document not found for mobile: $mobile");
          setState(() => isLoading = false);
          return;
        }

        final data = doc.data()!;
        final name = data['name'];
        final age = data['age'];
        final gender = data['gender'];
        final userType = data['userType'];
        final studentName = data['studentName'] ?? '';

        setState(() => isLoading = false);

        if (userType == "Parent" || userType == "Therapist") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentDashboardPage(
                name: name,
                age: age,
                mobile: mobile,
                gender: gender,
                whoYouAre: userType,
                studentName: studentName,
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
        print("FirebaseAuthException: ${e.code} - ${e.message}");
        setState(() => isLoading = false);

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
        print("Unexpected error during login: $e");
        setState(() => isLoading = false);
        _showSnackBar('An error occurred. Try again.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade300,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );

  ButtonStyle elevatedBtnStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF0A2D63),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
  );
}
