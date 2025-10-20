import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required String userId});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Welcome to MyMoneyHub 💰",
      "description":
      "Your personal finance companion — track income, expenses, and loans effortlessly in one place.",
      "icon": "🏦",
    },
    {
      "title": "Smart Overview 📊",
      "description":
      "Instantly view your total lending, liabilities, and balance summary on your home dashboard.",
      "icon": "📈",
    },
    {
      "title": "Quick Entries ⚡",
      "description":
      "Add lending, borrowing, or expenses in seconds — simple, fast, and accurate.",
      "icon": "✍️",
    },
    {
      "title": "Organize Parties 🤝",
      "description":
      "Keep records of people you lend to or borrow from, with full details and history.",
      "icon": "🧾",
    },
    {
      "title": "Sync with Firebase ☁️",
      "description":
      "Your data is safely stored in the cloud — access from any device, anytime.",
      "icon": "🔒",
    },
  ];

  Future<void> _nextPage() async {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      final userId = prefs.getString('userId') ?? "USR000";

      // ✅ Navigate to home safely
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, '/home',
            arguments: userId
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['icon']!, style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 30),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.deepPurple
                        : Colors.deepPurple.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _nextPage,
                child: Text(
                  _currentIndex == onboardingData.length - 1
                      ? "Get Started 🚀"
                      : "Next →",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
