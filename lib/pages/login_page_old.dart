import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/database/firebase_service.dart';
import 'home_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginByEmail = true; // default login method
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.blueAccent.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome Back 👋",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Login to continue",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 28),

                    // 🌟 Toggle Buttons for Email / Phone
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ToggleButtons(
                        isSelected: [_isLoginByEmail, !_isLoginByEmail],
                        onPressed: (index) {
                          setState(() {
                            _isLoginByEmail = index == 0;
                            _usernameController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        fillColor: Colors.blue.shade900,
                        selectedColor: Colors.white,
                        color: Colors.black87,
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          minWidth: 120,
                        ),
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.email, size: 18),
                              SizedBox(width: 6),
                              Text("Email"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 18),
                              SizedBox(width: 6),
                              Text("Phone"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Username Field (Email / Phone)
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: _isLoginByEmail
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      decoration: InputDecoration(
                        labelText:
                        _isLoginByEmail ? 'Email Address' : 'Phone Number',
                        prefixIcon: Icon(
                          _isLoginByEmail ? Icons.email : Icons.phone,
                          color: Colors.black87,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _isLoginByEmail
                              ? 'Enter your email'
                              : 'Enter your phone number';
                        }
                        if (_isLoginByEmail && !value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        if (!_isLoginByEmail && value.length < 10) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: Colors
                            .black87),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Error Message
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 16),

                    // 🔹 Login Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight
                            .normal),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Register Link
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text(
                        "Don't have an account? Register",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginByEmail) {
        // ✅ Email login
        final email = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        UserCredential userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final user = userCred.user;
        if (user == null) throw Exception("User not found");

        // ✅ Get user full name (from Firestore)
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userId = doc.data()?['userId'] ?? "User";

        // Navigate to HomePage
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => HomePage(userId: userId)),
          );
        }
      } else {
        // ✅ Phone login (custom validation)
        final phone = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .where('password', isEqualTo: password)
            .get();

        if (query.docs.isEmpty) {
          throw Exception("Invalid phone or password");
        }

        final userData = query.docs.first.data();

        // Navigate to HomePage
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(userId: userData['userId']),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Login failed";
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
