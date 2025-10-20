import 'package:flutter/material.dart';

class RegistrationConfirmationPage extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;


  const RegistrationConfirmationPage({
    Key? key,
    required this.fullName,
    required this.email,
    required this.phone,
  }) : super(key: key);

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Registration Successful",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text("Welcome, $fullName!",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Your username:"),
              const SizedBox(height: 5),
              Text(email,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500)),
              Text(
                phone.length == 13 ? phone.substring(3) : phone, // removes first 3 digits safely
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text("You may use either Email ID or 10 digit mobile number as your Username",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text("Go to Login",
                  style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
