import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ Custom App Ribbon for Home Page (No back button, logo centered, logout + notification on right)
PreferredSizeWidget buildHomeRibbon(
    BuildContext context, {
      required String userId,
    }) {
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.deepPurple.shade800,
    elevation: 6,
    toolbarHeight: 70,
    titleSpacing: 0,
    centerTitle: true,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔹 Placeholder to keep center alignment
        const SizedBox(width: 48),

        // 💰 Logo + App Name (Non-clickable)
        Row(
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

        // 🔔 Notification + 🚪 Logout Buttons
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Colors.white, size: 26),
              tooltip: "Notifications",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No new notifications")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 24),
              tooltip: "Logout",
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text("Confirm Logout"),
                    content: const Text("Do you really want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.black87)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}
