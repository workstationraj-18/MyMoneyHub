import 'package:expense_tracker/pages/add_party_page.dart';
import 'package:expense_tracker/pages/view_parties_page.dart';
import 'package:flutter/material.dart';
import '../widgets/app_ribbon.dart';
import '../widgets/home_ribbon.dart';
import 'add_entry_page.dart';
import 'view_entries_page.dart';
import 'ledger_page.dart';
import '../database/firebase_service.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({required this.userId, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  @override
  void initState() {
    super.initState();
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
                Text(
                  "${_getGreeting()}, ${widget.userId.split(' ').first}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // ✨ Refined tagline
                const Text(
                  "Smartly manage your lending, borrowing, and transactions — all in one place.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),

                // 🌟 App highlights (mini feature badges)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: const [
                    _FeatureBadge(icon: Icons.insights, label: "Real-time Balance Updates"),
                    _FeatureBadge(icon: Icons.trending_up, label: "Smart Analytics"),
                    _FeatureBadge(icon: Icons.security_rounded, label: "Secure Cloud Sync"),
                    _FeatureBadge(icon: Icons.auto_graph_rounded, label: "Detailed Transaction History"),
                  ],
                ),

                const SizedBox(height: 20),

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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEntryPage(userId: widget.userId),
                    ),
                  ),
                ),
                _buildActionTile(
                  icon: Icons.list_alt_rounded,
                  title: "View Entries",
                  subtitle: "Check your active and settled entries",
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ViewEntriesPage(userId: widget.userId),
                    ),
                  ),
                ),

                _buildActionTile(
                  icon: Icons.group_add_outlined,
                  title: "Add Party",
                  subtitle: "Create a new party record",
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPartyPage(userId: widget.userId),
                    ),
                  ),
                ),

                _buildActionTile(
                  icon: Icons.people_alt_outlined,
                  title: "View Party Details",
                  subtitle: "Manage and view all parties",
                  color: Colors.pinkAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewPartiesPage(userId: widget.userId),
                    ),
                  ),
                ),

                _buildActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Transaction History",
                  subtitle: "View your complete transaction log",
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LedgerPage(userId: widget.userId),
                    ),
                  ),
                ),
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
