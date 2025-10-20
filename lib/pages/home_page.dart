import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_footer.dart';
import '../widgets/home_ribbon.dart';
import '../database/firebase_service.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({required this.userId, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullName ='';
  final FirebaseService _firebaseService = FirebaseService();
  @override
  void initState() {
    super.initState();
    _loadUserFullName();
    _checkAndShowQuickTips();
  }


  Future<void> _loadUserFullName() async {
    final userData = await _firebaseService.getUserDataByUserId(widget.userId);
    if (userData != null && mounted) {
      setState(() {
        fullName = userData['name'] ?? 'Unknown';
      });
    }
  }


  Future<void> _checkAndShowQuickTips() async {
    final prefs = await SharedPreferences.getInstance();

    final hasShownTips = prefs.getBool('hasShownQuickTips') ?? false;

    if (!hasShownTips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQuickTipsDialog();
      });
      await prefs.setBool('hasShownQuickTips', true);
    }
  }

  void _showQuickTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "💡 Quick Tips",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "👉 Record your lending and borrowing easily.\n"
              "👉 Track balances in real-time.\n"
              "👉 Use the dashboard to monitor transactions.\n"
              "👉 Go to Settings → Parties to manage contacts.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }


  String _getGreeting() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)); // Convert to IST
    final hour = now.hour;

    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Custom App Ribbon with Notification Icon
      appBar: buildHomeRibbon(
        context,
        userId: widget.userId,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.streamEntries(userId: widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;
          final activeEntries = entries.where((e) => e['isSettled'] != true).toList();
          final settledEntries = entries.where((e) => e['isSettled'] == true).toList();

          double lendingBalance = 0;
          double liabilityBalance = 0;

          for (var e in activeEntries) {
            final type = e['entryType']?.toString().toUpperCase();
            final remaining = (e['remainingAmount'] ?? 0).toDouble();
            if (type == 'LEND') lendingBalance += remaining;
            if (type == 'BORROW') liabilityBalance += remaining;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 Greeting
                Text(
                  "${_getGreeting()}, ${fullName.isNotEmpty ? fullName.split(' ').first : 'User'}", style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 🧠 Smart Subtitle
                const Text(
                  "Welcome to MyMoneyHub — your smart financial companion.",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 6),

                // 💡 Expanded App Overview
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepPurple.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.shade50.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📊 Track. Manage. Simplify.",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                          letterSpacing: 0.3,
                        ),
                      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),

                      const SizedBox(height: 12),

                      _FeatureRow(
                        icon: Icons.assignment_turned_in_rounded,
                        color: Colors.deepPurple,
                        text: "Record every lend and borrow with clarity and confidence.",
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      _FeatureRow(
                        icon: Icons.show_chart_rounded,
                        color: Colors.blueAccent,
                        text: "Track real-time lending and liability balances effortlessly.",
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      _FeatureRow(
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        text: "Settle transactions instantly — auto-logged in your ledger.",
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      _FeatureRow(
                        icon: Icons.trending_up_rounded,
                        color: Colors.teal,
                        text: "Analyze financial trends and payment history smartly.",
                      ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      _FeatureRow(
                        icon: Icons.group_rounded,
                        color: Colors.orangeAccent,
                        text: "Manage trusted parties and stay organized with ease.",
                      ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideX(begin: -0.2),
                    ],
                  ),
                ),
                // 🔹 Entry Stats (your next section)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Active Entries",
                        activeEntries.length.toString(),
                        Icons.pending_actions,
                        Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        "Settled Entries",
                        settledEntries.length.toString(),
                        Icons.task_alt,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 🔹 Balance Summary
                const Text(
                  "Balance Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Lending Balance",
                        "₹${lendingBalance.toStringAsFixed(2)}",
                        Icons.trending_up_rounded,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        "Liability Balance",
                        "₹${liabilityBalance.toStringAsFixed(2)}",
                        Icons.trending_down_rounded,
                        Colors.deepOrange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 🔹 Quick Actions (keep existing)
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                _buildActionTile(
                  icon: Icons.add_circle_outline,
                  title: "Add New Entry",
                  subtitle: "Record a new lending or borrowing",
                  color: Colors.indigoAccent,
                  onTap: () => Navigator.pushNamed(
                    context, '/addNewEntry',arguments: widget.userId),
                ),
                _buildActionTile(
                  icon: Icons.list_alt_rounded,
                  title: "View Entries",
                  subtitle: "Check your active and settled entries",
                  color: Colors.deepPurple,
                  onTap: () => Navigator.pushNamed(
                    context, '/viewEntryList',arguments: widget.userId),
                ),

                _buildActionTile(
                  icon: Icons.group_add_outlined,
                  title: "Add Party",
                  subtitle: "Create a new party record",
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.pushNamed(
                    context, '/addNewParty',arguments: widget.userId),
                ),
//test
                _buildActionTile(
                  icon: Icons.people_alt_outlined,
                  title: "View Party Details",
                  subtitle: "Manage and view all parties",
                  color: Colors.pinkAccent,
                  onTap: () => Navigator.pushNamed(
                    context, '/viewPartyList',arguments: widget.userId),
                ),

                _buildActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Transaction History",
                  subtitle: "View your complete transaction log",
                  color: Colors.teal,
                  onTap: () => Navigator.pushNamed(
                    context, '/ledgerHistory',
                    arguments: widget.userId),
                ),
                // ⚙️ Footer Section
                const AppFooter(),
              ],
            ),
          );
        },
      ),

    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 22,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple.shade700),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}


class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color:
                isSelected ? Colors.deepPurple : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                isSelected ? Colors.deepPurple : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text page coming soon...')),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
