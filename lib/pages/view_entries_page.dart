import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../widgets/app_ribbon.dart';
import 'entry_details_page.dart';

class ViewEntriesPage extends StatefulWidget {
  final String userId;
  const ViewEntriesPage({required this.userId, super.key});

  @override
  State<ViewEntriesPage> createState() => _ViewEntriesPageState();
}

class _ViewEntriesPageState extends State<ViewEntriesPage>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String _filterType = "All"; // All | Lend | Borrow
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Map<String, dynamic>> _filterEntries(List<Map<String, dynamic>> list) {
    if (_filterType == "All") return list;
    return list
        .where((e) =>
    (e['entryType'] ?? '').toString().toLowerCase() ==
        _filterType.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppRibbon(context, userId: widget.userId),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("All"),
                selected: _filterType == "All",
                selectedColor: Colors.deepPurpleAccent.shade100,
                onSelected: (_) => setState(() => _filterType = "All"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Lending"),
                selected: _filterType == "Lend",
                selectedColor: Colors.deepPurpleAccent.shade100,
                onSelected: (_) => setState(() => _filterType = "Lend"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Borrowing"),
                selected: _filterType == "Borrow",
                selectedColor: Colors.deepPurpleAccent.shade100,
                onSelected: (_) => setState(() => _filterType = "Borrow"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: "Active Entries"),
              Tab(text: "Settled Entries"),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.streamEntries(userId: widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data!;
                final activeEntries =
                entries.where((e) => e['isSettled'] != true).toList();
                final settledEntries =
                entries.where((e) => e['isSettled'] == true).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEntryList(activeEntries),
                    _buildEntryList(settledEntries),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(List<Map<String, dynamic>> entries) {
    final filtered = _filterEntries(entries);

    if (filtered.isEmpty) return const Center(child: Text("No entries found"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final entry = filtered[i];
        final isSettled = entry['isSettled'] == true;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context, '/entryDetailsPage',
              arguments: {
                'userId': widget.userId,
                'entry': entry,
                'entryId': entry['entryId'],
              },
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _iconForEntryType(entry['entryType']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['partyName'] ?? 'Unknown Party',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${(entry['date'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')
                              .first}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        if (entry['purpose'] != null)
                          Text(
                            "Purpose: ${entry['purpose']}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${(entry['entryType'] ?? '')
                            .toString()
                            .toUpperCase()}ING",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _colorForEntryType(entry['entryType']),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${entry['amount'] ?? 0}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (entry['remainingAmount'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Rem: ₹${entry['remainingAmount']}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _iconForEntryType(String? type) {
    final upperType = (type ?? '').toUpperCase();

    final iconMap = {
      "LEND": Icons.arrow_upward,
      "BORROW": Icons.arrow_downward,
    };

    final colorMap = {
      "LEND": Colors.teal,
      "BORROW": Colors.redAccent,
    };

    return CircleAvatar(
      radius: 22,
      backgroundColor: colorMap[upperType] ?? Colors.grey,
      child: Icon(
        iconMap[upperType] ?? Icons.receipt_long,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Color _colorForEntryType(String? type) {
    final upperType = (type ?? '').toUpperCase();
    if (upperType == "LEND") return Colors.teal;
    if (upperType == "BORROW") return Colors.redAccent;
    return Colors.black87;
  }
}