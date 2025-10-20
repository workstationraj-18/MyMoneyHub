import 'package:expense_tracker/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../widgets/app_ribbon.dart';

class EntryDetailsPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? entry;
  final String? entryId;

  const EntryDetailsPage({
    super.key,
    required this.userId,
    this.entry,
    this.entryId,
  });

  @override
  State<EntryDetailsPage> createState() => _EntryDetailsPageState();
}

class _EntryDetailsPageState extends State<EntryDetailsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  Map<String, dynamic>? _entryData;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    if (widget.entry != null) {
      _entryData = widget.entry;
      setState(() {});
    } else if (widget.entryId != null) {
      setState(() => _isLoading = true);
      try {
        final entries = await _firebaseService.getEntriesByUserId(userId: widget.userId);
        final found = entries.firstWhere(
              (e) => e['entryId'] == widget.entryId,
          orElse: () => {},
        );
        if (found.isNotEmpty) {
          _entryData = found;
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    try {
      if (value == null) return "-";
      DateTime? date;
      if (value is Timestamp) {
        date = value.toDate();
      } else if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.tryParse(value);
      }
      if (date == null) return value.toString();
      return DateFormat("d MMM, yyyy HH:mm:ss").format(date);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildBoxField(String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox();
    String displayValue =
    (label.toLowerCase().contains("date") || label.toLowerCase().contains("created"))
        ? _formatDate(value)
        : value.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(Map<String, dynamic> entry) {
    final fields = [
      {"label": "Entry ID", "value": entry['entryId']},
      {"label": "Purpose", "value": entry['purpose']},
      {"label": "Expense Mode", "value": entry['mode']},
      {"label": "Platform", "value": entry['platform']},
      {"label": "Payment Method", "value": entry['paymentMethod']},
      {"label": "Date of Entry", "value": entry['date']},
      {"label": "Party ID", "value": entry['partyId']},
      {"label": "Note", "value": entry['note']},
      {"label": "Payment Method Name", "value": entry['methodName']},
      {"label": "Created At", "value": entry['createdAt']},
    ];

    final visibleFields = fields.where((f) => f['value'] != null && f['value'].toString().trim().isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 3,
          runSpacing: 3,
          children: visibleFields.map((f) {
            return SizedBox(
              width: isWide
                  ? (constraints.maxWidth / 2) - 12
                  : constraints.maxWidth,
              child: _buildBoxField(f['label'] as String, f['value']),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _settleEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Confirm Settlement"),
        content: const Text("Are you sure you want to mark this entry as settled?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || _entryData == null) return;
    try {
      final entry = _entryData!;
      final userId = entry['userId'];
      final entryId = entry['entryId'];
      if (userId == null || entryId == null) {
        debugPrint("❌ Cannot settle entry: missing userId or entryId");
        return;
      }
      await _firebaseService.syncLedger(
        userId,
        entryId,
        entry,
        true, // isSettled = true
        isUpdate: true, // because this is an existing entry
      );
      await _firebaseService.updateEntry(
        entry['entryId'],
        {
          'isSettled': true,
          'remainingAmount': 0,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry settled successfully ✅")),
        );
        setState(() {
          _entryData!['isSettled'] = true;
          _entryData!['remainingAmount'] = 0;
        });
      }
    }catch (e) {
      debugPrint("❌ Error settling entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error settling entry: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entry = _entryData ?? {};
    final isSettled = entry['isSettled'] == true;

    return Scaffold(
      backgroundColor: isSettled ? Colors.green.shade50 : Colors.white,
      appBar: buildAppRibbon(context, userId: widget.userId),
      body: _entryData == null
          ? const Center(child: Text("No entry found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Header section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSettled ? Colors.green.shade100 : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['partyName'] ?? "Unknown Party",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${(entry['entryType'] ?? 'N/A').toString().capitalize()}ing Entry",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: (entry['entryType']?.toString().toUpperCase() == "BORROW")
                                ? Colors.tealAccent.shade700
                                : Colors.pinkAccent.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${entry['amount'] ?? 0}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSettled ? Colors.green.shade800 : Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Remaining Amount
            Center(
              child: Text(
                "Remaining amount: ₹${entry['remainingAmount'] ?? 0}",
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Responsive Field Boxes
            _buildResponsiveGrid(entry),

            const SizedBox(height: 15),

            // 🔹 Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isSettled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("Settle this entry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13.5),
                    ),
                    onPressed: _settleEntry,
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 74, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13.5),
                  ),
                    onPressed: isSettled
                        ? null
                        : () async {
                      final updatedEntry = await Navigator.pushNamed(
                        context,
                        '/modifyEntry',
                        arguments: {
                          'userId': widget.userId,
                          'entry': entry,
                        },
                      );
                      if (updatedEntry != null && updatedEntry is Map<String, dynamic>) {
                        setState(() {
                          _entryData = updatedEntry; // update immediately
                        });
                      }
                    },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
