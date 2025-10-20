import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/utilities.dart';
import '../widgets/app_ribbon.dart';
import '../database/firebase_service.dart';

class LedgerPage extends StatefulWidget {
  final String userId;
  const LedgerPage({required this.userId, super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> ledgers = [],  parties = [];
  bool isLoading = true;
  String filterType = "all"; // ✅ lowercase for easy comparison

  @override
  void initState() {
    super.initState();
    _loadLedgers();
  }

  Future<void> _loadLedgers() async {
    try {
      // 🔹 Step 1: Get raw ledgers from Firebase
      final rawLedgers = await _firebaseService.getLedgerEntries(userId: widget.userId);

      // 🔹 Step 2: Process each ledger asynchronously
      ledgers = await Future.wait(rawLedgers.map((l) async {
        final entry = Map<String, dynamic>.from(l);
        // Normalize transactionType
        entry['tranType'] = (l['tranType'] ?? '').toString().trim().toUpperCase();
        // Resolve "to" name
        if (l['to'].toString().startsWith("PRT")) {
          final toName = await _firebaseService.getPartyNameByPartyId(l['to'].toString());
          entry['to'] = (toName != null && toName.isNotEmpty)
              ? extractFirstName(toName)
              : l['to'];
        } else {
          entry['to'] = extractFirstName(await _firebaseService.getUserFullNameByUserId(widget.userId));
        }
        // Resolve "from" name
        if (l['from'].toString().startsWith("PRT")) {
          final fromName = await _firebaseService.getPartyNameByPartyId(l['from'].toString());
          entry['from'] = (fromName != null && fromName.isNotEmpty)
              ? extractFirstName(fromName)
              : l['from'];
        } else {
          entry['from'] = extractFirstName(await _firebaseService.getUserFullNameByUserId(widget.userId));
        }
        entry['createdAt'] = l['createdAt'];
        return entry;
      }));

      // 🔹 Step 3: Sort by date (if applicable)
      ledgers.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        return bDate.toString().compareTo(aDate.toString());
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading ledgers: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Filter logic (case-insensitive)
    final filtered = filterType == "all"
        ? ledgers
        : ledgers.where((l) {
      final type = (l['tranType'] ?? '').toString().toUpperCase();
      return type == filterType.toUpperCase();
    }).toList();

    return Scaffold(
      appBar: buildAppRibbon(context, userId: widget.userId),
      body: Column(
        children: [
          // 🔹 Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("ALL"),
                  _buildFilterChip("DEBIT"),
                  _buildFilterChip("CREDIT"),
                  _buildFilterChip("LIABILITY"),
                  _buildFilterChip("PAYMENT"),
                ],
              ),
            ),
          ),
          const Divider(height: 0),

          // 🔹 Ledger list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text("No ledger records found"))
                : RefreshIndicator(
              onRefresh: _loadLedgers,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final l = filtered[i];
                  final tranType = (l['tranType'] ?? '').toString();
                  final amount = l['amount']?.toString() ?? "0";
                  final from = l['from'] ?? "Unknown";
                  final to = l['to'] ?? "Unknown";

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: _iconForTransaction(tranType),
                      title: Text(
                        "$from → $to",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${tranType}  •  ₹${(double.tryParse(amount.toString()) ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Date: ${_formatDate(l['createdAt'])}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // 🔹 Right side content (Ledger ID)
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.receipt_long, size: 16, color: Colors.blueGrey),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${l['ledgerId'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Filter chip builder
  Widget _buildFilterChip(String label) {
    final isSelected = filterType == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          label[0].toUpperCase() + label.substring(1).toLowerCase(),
        ),
        selected: isSelected,
        selectedColor: Colors.deepPurpleAccent.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        onSelected: (_) => setState(() => filterType = label.toLowerCase()),
      ),
    );
  }

  // 🔹 Transaction type icons
  Widget _iconForTransaction(String? type) {
    final upperType = (type ?? '').toUpperCase();
    final iconMap = {
      "DEBIT": Icons.arrow_upward,
      "CREDIT": Icons.arrow_downward,
      "LIABILITY": Icons.trending_down_outlined,
      "PAYMENT": Icons.credit_card_sharp
    };
    final colorMap = {
      "DEBIT": Colors.redAccent,
      "CREDIT": Colors.green,
      "LIABILITY": Colors.orangeAccent,
      "PAYMENT": Colors.blueAccent,
    };

    return CircleAvatar(
      backgroundColor: colorMap[upperType] ?? Colors.grey.shade500,
      child: Icon(
        iconMap[upperType] ?? Icons.receipt_long,
        color: Colors.white,
      ),
    );
  }

  // 🔹 Date formatter
  String _formatDate(dynamic raw) {
    if (raw == null) return "-";
    try {
      DateTime? dt;

      if (raw is DateTime) dt = raw;
      if (raw is Timestamp) dt = raw.toDate();
      if (raw is String) dt = DateTime.tryParse(raw);

      if (dt == null) return raw.toString();
      return DateFormat("d MMM yyyy, HH:mm").format(dt);
    } catch (_) {
      return raw.toString();
    }
  }
}
