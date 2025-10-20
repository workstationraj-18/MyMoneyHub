// lib/pages/add_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../widgets/app_ribbon.dart';

class AddEntryPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? entry;
  final Map<String, dynamic>? existingEntry;

  const AddEntryPage({
    super.key,
    required this.userId,
    this.entry,
    this.existingEntry,
  });

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  // -------------------------------------------------------
  // 🧩 Core Fields and State
  // -------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  // Controllers
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final methodNameController = TextEditingController();
  final customPurposeController = TextEditingController();
  final customPlatformController = TextEditingController();
  final customPaymentMethodController = TextEditingController();

  // FocusNodes
  final FocusNode entryTypeFocus = FocusNode();
  final FocusNode partyFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode dateFocus = FocusNode();
  final FocusNode modeFocus = FocusNode();
  final FocusNode purposeFocus = FocusNode();
  final FocusNode platformFocus = FocusNode();
  final FocusNode paymentMethodFocus = FocusNode();
  final FocusNode methodNameFocus = FocusNode();
  final FocusNode noteFocus = FocusNode();
  final FocusNode customPurposeFocus = FocusNode();

  // Form state
  String? entryType;
  String? selectedPartyId;
  String? mode = "Online Expense";
  String? purpose;
  String? platform;
  String? paymentMethod;
  DateTime selectedDate = DateTime.now();
  bool isSettled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Data lists
  List<Map<String, dynamic>> parties = [];

  // -------------------------------------------------------
  // 🧠 Dropdown Constants
  // -------------------------------------------------------
  final modes = ["Online Expense", "Offline Expense"];

  final onlinePurposes = [
    "Item Purchase",
    "Loan",
    "Recharge/Bill Payments",
    "Food Delivery",
    "Transportation",
    "Healthcare & Medicine",
    "Insurance Payment",
    "Others"
  ];

  final offlinePurposes = [
    "Loan",
    "Recharge/Bill Payments",
    "Food/Grocery/Dining",
    "Transportation",
    "Insurance Payment",
    "Healthcare & Medicine",
    "Other Offline Expenses"
  ];

  final allPaymentMethods = [
    "UPI",
    "Credit Card",
    "Wallet",
    "Cash",
    "Debit Card",
    "Others"
  ];

  final Map<String, List<String>> platformOptions = {
    "Item Purchase": ["Flipkart", "Amazon", "Myntra", "Paytm", "Others"],
    "Food Delivery": ["Swiggy", "Zomato", "Zepto", "Blinkit", "Others"],
    "Recharge/Bill Payments": ["PhonePe", "CRED", "Paytm", "Others"],
    "Transportation": ["Uber", "Ola", "Rapido", "Others"],
    "Loan": ["GPay", "PhonePe", "CRED", "Others"],
    "Healthcare & Medicine": ["PharmEasy", "Apollo", "Others"],
    "Insurance Payment": ["GPay", "CRED", "Paytm", "Others"],
  };

  // -------------------------------------------------------
  // 🏁 Init + Dispose
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    amountFocus.addListener(() {
      if (!amountFocus.hasFocus) _formatAmountToTwoDecimals();
    });
    _loadParties();
    _initializeFields();
  }

  @override
  void dispose() {
    for (final c in [
      amountController,
      noteController,
      methodNameController,
      customPurposeController,
      customPlatformController,
      customPaymentMethodController
    ]) {
      c.dispose();
    }
    for (final f in [
      entryTypeFocus,
      partyFocus,
      amountFocus,
      dateFocus,
      modeFocus,
      purposeFocus,
      platformFocus,
      paymentMethodFocus,
      methodNameFocus,
      noteFocus,
      customPurposeFocus
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------
  // 🧩 Utility Getters
  // -------------------------------------------------------
  List<String> get purposeOptions => mode == "Online Expense" ? onlinePurposes : offlinePurposes;

  List<String> get paymentMethods => mode == "Online Expense"
      ? ["UPI", "Credit Card", "Debit Card", "Net Banking", "Others"]
      : ["Cash", "Credit Card", "Debit Card"];

  bool get hidePaymentMethod =>
      mode == "Online Expense" &&
          ["Loan", "Recharge/Bill Payments", "Insurance Payment"].contains(purpose);

  Color get accentColor {
    if (entryType == 'Lend') return Colors.teal.shade900;
    if (entryType == 'Borrow') return Colors.pink.shade900;
    return Colors.black87;
  }

  // -------------------------------------------------------
  // 🔧 Initialization Helpers
  // -------------------------------------------------------
  void _initializeFields() {
    final e = widget.existingEntry ?? widget.entry;
    if (e == null) return;

    entryType = e['entryType'];
    selectedPartyId = e['partyId'];
    amountController.text = _formatAmount(e['amount']);
    noteController.text = e['note'] ?? '';
    mode = e['mode'];
    purpose = e['purpose'];
    platform = e['platform'];
    paymentMethod = e['paymentMethod'];
    methodNameController.text = e['methodName'] ?? '';
    isSettled = e['isSettled'] == true || e['isSettled'] == 1;

    selectedDate = _parseDate(e['date']);
    if (purpose == "Others" || purpose == "Other Offline Expenses") {
      customPurposeController.text = e['customPurpose'] ?? '';
    }
    if (platform == "Others") customPlatformController.text = e['customPlatform'] ?? '';
    if (paymentMethod == "Others") customPaymentMethodController.text = e['customPaymentMethod'] ?? '';
  }

  Future<void> _loadParties() async {
    try {
      final uid = await _firebaseService.getFirestoreUserId();
      if (uid == null) return;

      final rawParties = await _firebaseService.getPartiesByUserId(uid);
      setState(() {
        parties = rawParties.map((p) => {
          'partyId': p['partyId'] ?? p['id'],
          'name': p['name'] ?? '',
          ...p,
        }).toList();
      });
    } catch (e) {
      debugPrint("❌ Error loading parties: $e");
    }
  }

  // -------------------------------------------------------
  // 🔢 Formatting Helpers
  // -------------------------------------------------------
  String _formatAmount(dynamic amt) {
    if (amt == null) return '';
    final parsed = (amt is num) ? amt : double.tryParse(amt.toString());
    return parsed?.toStringAsFixed(2) ?? '';
  }

  DateTime _parseDate(dynamic rawDate) {
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    if (rawDate is String) {
      try {
        return DateTime.parse(rawDate);
      } catch (_) {}
    }
    return DateTime.now();
  }

  void _formatAmountToTwoDecimals() {
    final text = amountController.text.trim();
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return;
    amountController.text = parsed.toStringAsFixed(2);
  }

  String _getPartyName(String? id) {
    final found = parties.firstWhere(
          (p) => p['partyId']?.toString() == id,
      orElse: () => {'name': 'Unknown'},
    );
    return found['name'] ?? 'Unknown';
  }

  // -------------------------------------------------------
  // 💾 Save Entry Logic
  // -------------------------------------------------------
  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final entryData = _buildEntryData();
    final confirm = await _confirmDialog(entryData);
    if (confirm != true) return;

    // ⏩ Show instant feedback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String entryId;
      if (widget.entry == null && widget.existingEntry == null) {
        entryId = await _firebaseService.insertEntry(entryData);
      } else {
        final existing = widget.existingEntry ?? widget.entry!;
        entryId = existing['entryId'];
        await _firebaseService.updateEntry(entryId, entryData);
      }

      await _firebaseService.syncLedger(
        widget.userId,
        entryId,
        entryData,
        isSettled,
        isUpdate: widget.entry != null || widget.existingEntry != null,
      );

      Navigator.pop(context); // Close loading dialog ✅
      await _showSuccessDialog(); // Show success popup
      Navigator.pop(context, {'entryId': entryId, ...entryData});
    } catch (e) {
      Navigator.pop(context); // Close loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save entry ❌")),
      );
    }
  }

  Map<String, dynamic> _buildEntryData() {
    final amountParsed = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;
    return {
      'entryType': entryType,
      'partyId': selectedPartyId,
      'partyName': _getPartyName(selectedPartyId),
      'amount': amountParsed,
      'remainingAmount': isSettled ? 0 : amountParsed,
      'date': selectedDate,
      'mode': mode,
      'purpose': (purpose == "Others") ? customPurposeController.text : purpose,
      'platform': (platform == "Others") ? customPlatformController.text : platform,
      'paymentMethod':
      (paymentMethod == "Others") ? customPaymentMethodController.text : paymentMethod,
      'methodName': methodNameController.text.trim(),
      'note': noteController.text.trim(),
      'isSettled': isSettled,
      if (widget.entry != null || widget.existingEntry != null)
        'updatedAt': DateTime.now(),
    };
  }

  // -------------------------------------------------------
  // 🪟 Dialog Helpers
  // -------------------------------------------------------
  Future<bool?> _confirmDialog(Map<String, dynamic> data) {
    final entryType = data['entryType'];
    final amount = data['amount'];
    final partyName = data['partyName'];
    // 🧠 Decide message text based on entry type
    String contentText;
    if (entryType == "Lend") {
      contentText = "Add Lending entry of ₹$amount to $partyName?";
    } else if (entryType == "Borrow") {
      contentText = "Add Borrowing entry of ₹$amount from $partyName?";
    } else {
      contentText = "Add entry for ₹$amount with $partyName?";
    }
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.entry == null ? 'Confirm Add Entry' : 'Confirm Update Entry'),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Yes, Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        content: Text(
          widget.entry == null
              ? "Entry added successfully ✅"
              : "Entry updated successfully ✅",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      FocusScope.of(context).requestFocus(modeFocus);
    }

  }


  // -------------------------------------------------------
  // 🧱 UI Build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppRibbon(context, userId: widget.userId),
      backgroundColor: Colors.grey[100],
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: _getInputDecorationTheme(accentColor),
          iconTheme: IconThemeData(color: accentColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // 🪟 Form inside window (Card)
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Text(
                              widget.existingEntry == null
                                  ? "Add New Entry"
                                  : "✏️ Edit Entry",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Form Fields
                            _buildDropdowns(),
                            const SizedBox(height: 20),

                            // Save / Update button
                            ElevatedButton.icon(
                              onPressed: _saveEntry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade800,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: Text(
                                widget.existingEntry == null
                                    ? "Add Entry"
                                    : "Update Entry",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  InputDecorationTheme _getInputDecorationTheme(Color color) {
    return InputDecorationTheme(
      labelStyle: TextStyle(color: color),
      prefixIconColor: color,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return "Amount required";
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount <= 0) return "Enter valid amount";
    return null;
  }

  Widget dynamicSpacing({bool visible = true, double height = 12}) {
    return visible ? SizedBox(height: height) : const SizedBox.shrink();
  }


  // TODO: Split Dropdowns/Fields into helper widgets (for brevity here).
  Widget _buildDropdowns() {
    Widget spacing({double height = 12}) => SizedBox(height: height);
    final color = accentColor;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: _getInputDecorationTheme(color),
        iconTheme: IconThemeData(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entry Type
          DropdownButtonFormField<String>(
            focusNode: entryTypeFocus,
            value: entryType,
            decoration: const InputDecoration(
              labelText: "Entry Type",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.swap_vert),
            ),
            items: ["Lend", "Borrow"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              setState(() => entryType = val);
              FocusScope.of(context).requestFocus(partyFocus);
            },
            validator: (val) => val == null || val.isEmpty ? "Please select Entry Type" : null,
          ),
          spacing(),

          // Party dropdown
          DropdownButtonFormField<String>(
            value: parties.any((p) => p['partyId']?.toString() == selectedPartyId) ? selectedPartyId : null,
            decoration: const InputDecoration(
              labelText: 'Select Party',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
            ),
            items: [
              ...parties.map((p) => DropdownMenuItem(
                value: p['partyId']?.toString(),
                child: Text(p['name']?.toString() ?? 'Unknown'),
              )),
              const DropdownMenuItem(
                value: 'ADD_NEW_PARTY',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('Add New Party'),
                  ],
                ),
              ),
            ],
            onChanged: (val) async {
              if (val == 'ADD_NEW_PARTY') {
                final newParty = await Navigator.pushNamed(context, '/addNewParty', arguments: widget.userId);
                if (newParty != null && newParty is Map<String, dynamic>) {
                  final normalizedParty = {
                    'partyId': newParty['partyId'] ?? '',
                    'name': newParty['name'] ?? '',
                    ...newParty,
                  };
                  setState(() {
                    parties.add(normalizedParty);
                    selectedPartyId = normalizedParty['partyId'];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("✅ '${normalizedParty['name']}' added and selected.")),
                  );
                }
              } else {
                setState(() => selectedPartyId = val);
              }
            },
            validator: (val) => val == null || val.isEmpty ? 'Please select party' : null,
          ),
          spacing(),

          // Amount
          TextFormField(
            focusNode: amountFocus,
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(
              labelText: "Amount",
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter amount";
              final parsed = double.tryParse(val.replaceAll(',', ''));
              if (parsed == null || parsed <= 0) return "Enter valid amount";
              return null;
            },
            onEditingComplete: () {
              _formatAmountToTwoDecimals();
              FocusScope.of(context).requestFocus(dateFocus);
            },
          ),
          spacing(),

          // Date
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: "Date of Entry",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${selectedDate.toLocal()}".split(' ')[0]),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          spacing(),

          // Mode
          DropdownButtonFormField<String>(
            focusNode: modeFocus,
            value: mode,
            decoration: const InputDecoration(
              labelText: "Expense Mode",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.compare_arrows),
            ),
            items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              setState(() {
                mode = val;
                purpose = null;
                platform = null;
                paymentMethod = null;
              });
              FocusScope.of(context).requestFocus(purposeFocus);
            },
          ),
          spacing(),

          // Purpose
          DropdownButtonFormField<String>(
            focusNode: purposeFocus,
            value: (purposeOptions.contains(purpose)) ? purpose : null,
            decoration: const InputDecoration(
              labelText: "Purpose",
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: purposeOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              setState(() {
                purpose = val;
                platform = null;
                paymentMethod = null;
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                if (val == "Others" || val == "Other Offline Expenses") {
                  FocusScope.of(context).requestFocus(customPurposeFocus);
                } else if (mode == "Online Expense" && platformOptions.containsKey(val)) {
                  FocusScope.of(context).requestFocus(platformFocus);
                } else {
                  FocusScope.of(context).requestFocus(paymentMethodFocus);
                }
              });
            },
          ),

          // Custom Purpose
          if (purpose == "Others" || purpose == "Other Offline Expenses") ...[
            dynamicSpacing(),
            TextFormField(
              focusNode: customPurposeFocus,
              controller: customPurposeController,
              decoration: const InputDecoration(
                labelText: "Enter custom purpose",
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          dynamicSpacing(visible: mode == "Online Expense" && platformOptions.containsKey(purpose)),

          // Platform (online-only)
          if (mode == "Online Expense" && platformOptions.containsKey(purpose)) ...[
            DropdownButtonFormField<String>(
              focusNode: platformFocus,
              value: ((platformOptions[purpose] ?? []).contains(platform)) ? platform : null,
              decoration: const InputDecoration(
                labelText: "Select Platform",
                prefixIcon: Icon(Icons.language_outlined),
                border: OutlineInputBorder(),
              ),
              items: (platformOptions[purpose] ?? []).map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => platform = val),
            ),
          ],
          dynamicSpacing(visible: platform == "Others"),
          if (platform == "Others") ...[
            TextFormField(
              controller: customPlatformController,
              decoration: const InputDecoration(
                labelText: "Enter custom platform",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
          dynamicSpacing(
            visible: !(mode == "Online Expense" &&
                (purpose == "Loan" || purpose == "Recharge/Bill Payments" || purpose == "Insurance Payment")),
          ),

          // Payment Method
          if (!hidePaymentMethod) ...[
            DropdownButtonFormField<String>(
              focusNode: paymentMethodFocus,
              value: (paymentMethods.contains(paymentMethod)) ? paymentMethod : null,
              decoration: const InputDecoration(
                labelText: "Select Payment Method",
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(),
              ),
              items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                setState(() => paymentMethod = val);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (val != "Others") FocusScope.of(context).requestFocus(methodNameFocus);
                });
              },
            ),
          ],
          dynamicSpacing(visible: paymentMethod == "Others"),
          if (paymentMethod == "Others") ...[
            TextFormField(
              controller: customPaymentMethodController,
              decoration: const InputDecoration(
                labelText: "Enter custom payment method",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
          dynamicSpacing(visible: paymentMethod != null && paymentMethod != "Others"),

          // Method name (optional)
          if (paymentMethod != null && paymentMethod != "Others") ...[
            spacing(),
            TextFormField(
              focusNode: methodNameFocus,
              controller: methodNameController,
              decoration: InputDecoration(
                labelText: "${paymentMethod!} Name (Optional)",
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          spacing(),

          // Note
          TextFormField(
            focusNode: noteFocus,
            controller: noteController,
            decoration: const InputDecoration(
              labelText: "Note (Optional)",
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          spacing(),
          // Settled card
          // ✅ Show "Mark as Settled" toggle only for NEW entries
          if (widget.existingEntry == null)
            Card(
              elevation: 3,
              color: isSettled ? Colors.green[50] : Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(
                  isSettled ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSettled ? Colors.green : Colors.red,
                ),
                title: const Text(
                  "Mark as Settled",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Switch(
                  activeColor: Colors.green,
                  value: isSettled,
                  onChanged: (v) => setState(() => isSettled = v),
                ),
              ),
            ),
          if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

