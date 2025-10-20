import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../widgets/app_footer.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginByEmail = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // By default, focus the email field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocus);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }


  String _getFriendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found. Please register first.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_isLoginByEmail) {
        final email = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        final userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final user = userCred.user;
        if (user == null) throw Exception("User not found");

        // 🔹 Get Firestore user data using UID
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          throw Exception("User data not found in Firestore");
        }

        final data = doc.data()!;
        final userId = data['userId']; // 👈 Your app’s internal userId
        final fullName = data['fullName'] ?? "User";

        // ✅ Save to SharedPreferences for app-wide use
        await prefs.setString('userId', userId);
        await prefs.setString('userFullName', fullName);
        await prefs.setBool('keepLoggedIn', true);

        final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

        if (!seenOnboarding) {
          Navigator.pushReplacementNamed(
            context, '/home',arguments: userId //Change this to onboarding
          );
        } else {
          Navigator.pushReplacementNamed(
            context, '/home', arguments: userId
          );
        }
      } else {
        // 🔹 Phone login mode
        final phone = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception("No account found for this phone number");
        }

        final data = query.docs.first.data();
        final email = data['email'];
        final userId = data['userId']; // 👈 internal ID
        final fullName = data['fullName'] ?? 'User';

        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        await prefs.setString('userId', userId);
        await prefs.setString('userFullName', fullName);
        await prefs.setBool('keepLoggedIn', true);

        final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

        if (!seenOnboarding) {
          Navigator.pushReplacementNamed(
              context, '/home',arguments: userId //Change this to onboarding
          );
        } else {
          Navigator.pushReplacementNamed(
            context, '/home', arguments: userId,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFriendlyError(e.code));
    } catch (e) {
      setState(() => _errorMessage = "Invalid credentials. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 100, left: 24, right: 24, bottom: 24),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.indigo[700], size: 40),
                                const SizedBox(width: 10),
                                Text(
                                  "MyMoneyHub",
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text("Login to continue",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.blueGrey)),
                            const SizedBox(height: 28),
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

                                  // 🪄 Wait until after the widget rebuilds, then focus the right field
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    FocusScope.of(context)
                                        .requestFocus(index == 0 ? _emailFocus : _phoneFocus);
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                fillColor: Colors.indigo.shade900,
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
                            TextFormField(
                              controller: _usernameController,
                              focusNode: _isLoginByEmail ? _emailFocus : _phoneFocus,
                              keyboardType:
                              _isLoginByEmail ? TextInputType.emailAddress : TextInputType.number,
                              maxLength: _isLoginByEmail ? null : 10,
                              onChanged: (value) {
                                if (!_isLoginByEmail && value.length == 10) {
                                  // Move to password field automatically
                                  FocusScope.of(context).requestFocus(_passwordFocus);
                                }
                              },
                              decoration: InputDecoration(
                                counterText: '',
                                labelText: _isLoginByEmail ? 'Email Address' : 'Phone Number',
                                prefixIcon: Icon(
                                  _isLoginByEmail ? Icons.email : Icons.phone,
                                  color: Colors.black87,
                                ),
                                prefixText: _isLoginByEmail ? null : '+91 ',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              inputFormatters:
                              _isLoginByEmail ? [] : [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _isLoginByEmail
                                      ? 'Enter your email'
                                      : 'Enter your phone number';
                                }
                                if (_isLoginByEmail && !value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                if (!_isLoginByEmail && value.length != 10) {
                                  return 'Enter a valid 10-digit number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock, color: Colors.black87),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _loginUser(),
                              validator: (value) =>
                              value == null || value.isEmpty ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 16),
                            if (_errorMessage != null)
                              Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                              onPressed: _loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade900,
                                foregroundColor: Colors.white,
                                minimumSize:
                                const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Login',
                                  style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/register'),
                              child: const Text(
                                "Don't have an account? Register",
                                style: TextStyle(color: Colors.indigoAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
