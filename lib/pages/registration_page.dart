import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/database/firebase_service.dart';
import 'registration_confirmation_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  String? gender;
  bool consent = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? dob;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    firstNameController.addListener(_updateFullName);
    middleNameController.addListener(_updateFullName);
    lastNameController.addListener(_updateFullName);

    emailController.addListener(_updateUsername);
    phoneController.addListener(_updateUsername);
  }

  void _updateFullName() {
    final f = firstNameController.text.trim();
    final m = middleNameController.text.trim();
    final l = lastNameController.text.trim();
    final parts = [f, m, l].where((p) => p.isNotEmpty).toList();
    fullNameController.text = parts.join(' ');
  }

  void _updateUsername() {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    if (email.isNotEmpty && phone.isNotEmpty) {
      usernameController.text = '$email | $phone';
    } else if (email.isEmpty) {
      usernameController.text = phone;
    } else if (phone.isEmpty) {
      usernameController.text = email;
    } else {
      usernameController.text = '';
    }
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return "$fieldName is required";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
      return "Only letters allowed in $fieldName";
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email required";
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Invalid email";
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone required";
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return "Enter valid 10-digit phone";
    }
    return null;
  }

  Future<void> _registerUser() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = "Please fix validation errors above.");
      return;
    }

    if (!consent) {
      setState(() => _errorMessage = "Please confirm that details are correct.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();

      // 🔹 Check if phone already exists
      final phoneExists = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneExists.docs.isNotEmpty) {
        setState(() {
          _errorMessage = "Phone number already registered.";
          _isLoading = false;
        });
        return;
      }

      // 🔹 Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user.');

      // 🔹 Prepare Firestore data
      final userData = {
        'uid': user.uid,
        'fullName': fullNameController.text.trim(),
        'phone': phone,
        'email': email,
        'username': usernameController.text.trim(),
        'gender': gender,
        'dob': dob?.toIso8601String(),
      };

      // 🔹 Save to Firestore (with custom ID)
      await _firebaseService.createUser(user.uid, userData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );

      Navigator.pushReplacementNamed(
        context,
        '/registrationConfirmation',
        arguments: {
          'fullName': fullNameController.text.trim(),
          'email': email,
          'phone': phone,
        },
      );
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email format.';
      }
        setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet,
                color: Colors.deepPurple[50], size: 28),
            const SizedBox(width: 8),
            Text(
              "MyMoneyHub",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[50],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        elevation: 4,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Scrollbar(
        radius: const Radius.circular(8),
        thickness: 6,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900), // ✅ reduced width
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Register",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(firstNameController, "First Name", Icons.person,
                          validator: (v) => validateName(v, 'First Name')),
                      const SizedBox(height: 12),
                      _buildTextField(middleNameController, "Middle Name (Optional)", Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildTextField(lastNameController, "Last Name", Icons.person_outline,
                          validator: (v) => validateName(v, 'Last Name')),
                      const SizedBox(height: 12),
                      _buildTextField(fullNameController, "Full Name", Icons.badge, readOnly: true),
                      const SizedBox(height: 12),
                      _buildTextField(phoneController, "Phone", Icons.phone,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: validatePhone,
                          prefixText: "+91 "),
                      const SizedBox(height: 12),
                      _buildTextField(emailController, "Email", Icons.email,
                          keyboardType: TextInputType.emailAddress, validator: validateEmail),
                      const SizedBox(height: 12),
                      _buildTextField(usernameController, "Username", Icons.account_box, readOnly: true),
                      const SizedBox(height: 12),
                      _buildTextField(passwordController, "Password", Icons.lock, obscureText: true,
                          validator: (v) => v == null || v.isEmpty ? "Password required" : null),
                      const SizedBox(height: 12),
                      _buildTextField(confirmPasswordController, "Confirm Password", Icons.lock_outline,
                          obscureText: true,
                          validator: (v) => v != passwordController.text
                              ? "Passwords do not match"
                              : null),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setState(() => gender = val),
                        validator: (val) => val == null ? 'Select gender' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDobField(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: consent,
                            onChanged: (v) => setState(() => consent = v ?? false),
                          ),
                          const Expanded(
                            child: Text('I confirm that all entered details are correct.'),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 14),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Register',
                            style: TextStyle(fontSize: 16, color: Colors.deepPurple.shade50),
                      ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Already have an account? Login',
                          style: TextStyle(fontSize: 14, color: Colors.indigoAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        bool readOnly = false,
        bool obscureText = false,
        TextInputType? keyboardType,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        String? prefixText,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildDobField() {
    return TextFormField(
      controller: dobController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date of Birth (Optional)',
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dob ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            dob = picked;
            dobController.text = picked.toLocal().toString().split(' ')[0];
          });
        }
      },
    );
  }
}
