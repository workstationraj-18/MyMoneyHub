import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home_page.dart';

/// ✅ Reusable App Ribbon (Header)
PreferredSizeWidget buildAppRibbon(
    BuildContext context, {
      String? userId,
      bool showBackButton = true,
      Widget? trailing,
    }) {
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.deepPurple.shade800, // ✅ Neutral tone
    elevation: 6,
    toolbarHeight: 70,
    titleSpacing: 0,
    centerTitle: true,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔙 Back Button (conditionally shown)
        if (showBackButton)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
            tooltip: "Back",
          )
        else
          const SizedBox(width: 48), // placeholder to keep spacing consistent

        // 💰 Logo + App Name (Center)
        GestureDetector(
          onTap: () {
            // Navigate home only if not already there
            if (showBackButton && userId != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(userId: userId),
                ),
                    (route) => false,
              );
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click, // 👆 Show hand cursor
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.deepPurple[50],
                  size: 28,
                ),
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
          ),
        ),

        // 🚪 Logout Button
        Row(
          children: [
            // Optional trailing widget (e.g., notification icon)
            if (trailing != null) trailing,

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
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                    context,
                    '/login',
                        (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}
