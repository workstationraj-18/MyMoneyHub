// lib/pages/add_entry_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_service.dart';
import '../widgets/app_ribbon.dart';
import 'add_party_page.dart';

class AddEntryPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? entry;
  final Map<String, dynamic>? existingEntry; // 👈 optional parameter

  const AddEntryPage({super.key, required this.userId, this.entry,  this.existingEntry});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  // Controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController methodNameController = TextEditingController();
  final TextEditingController customPurposeController = TextEditingController();
  final TextEditingController customPlatformController = TextEditingController();
  final TextEditingController customPaymentMethodController = TextEditingController();

  // FocusNodes for smart focus behavior
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
  List<Map<String, dynamic>> parties = [];
  Map<String, dynamic>? selectedParty;


  // Form state
  String? entryType; // "Lend" / "Borrow"
  String? selectedPartyId;
  String? mode = "Online Expense";
  String? purpose;
  String? platform;
  String? paymentMethod;
  DateTime selectedDate = DateTime.now();
  bool isSettled = false;

  List<Map<String, dynamic>> partyList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Dropdown data
  final List<String> modes = ["Online Expense", "Offline Expense"];
  final List<String> onlinePurposes = [
    "Item Purchase",
    "Loan",
    "Recharge/Bill Payments",
    "Food Delivery",
    "Transportation",
    "Healthcare & Medicine",
    "Insurance Payment",
    "Others"
  ];
  final List<String> offlinePurposes = [
    "Loan",
    "Recharge/Bill Payments",
    "Food/Grocery/Dining",
    "Transportation",
    "Insurance Payment",
    "Healthcare & Medicine",
    "Other Offline Expenses"
  ];

  final List<String> allPaymentMethods = [
    "UPI",
    "Credit Card",
    "Wallet",
    "Cash",
    "Debit Card",
    "Others"
  ];

  List<String> get purposeOptions {
    return (mode == "Online Expense") ? onlinePurposes : offlinePurposes;
  }

  List<String> getFilteredPaymentMethods() {
    if ((mode ?? "") == "Online Expense") {
      // Remove Cash in Online mode
      return allPaymentMethods.where((m) => m != "Cash").toList();
    } else {
      // Offline mode (or if mode is null)
      return ["Cash", "Credit Card", "Debit Card"];
    }
  }

  // 🔹 Add this inside your State class (e.g. _AddExpenseState)
  List<String> get paymentMethods {
    if (mode == "Online Expense") {
      // Online Expense → exclude Cash
      return ["UPI", "Credit Card", "Debit Card", "Net Banking", "Others"];
    } else {
      // Offline Expense → only show cash/card methods
      return ["Cash", "Credit Card", "Debit Card"];
    }
  }



  final Map<String, List<String>> platformOptions = {
    "Item Purchase": [
      "Flipkart",
      "Amazon",
      "Myntra",
      "Paytm",
      "Tata CLiQ",
      "Meesho",
      "Others"
    ],
    "Food Delivery": [
      "Swiggy",
      "Zomato",
      "Big Basket",
      "Amazon Fresh",
      "Flipkart Kilo",
      "Zepto",
      "Instamart",
      "Blinkit",
      "Others"
    ],
    "Recharge/Bill Payments": [
      "PhonePe",
      "CRED",
      "GPay",
      "Flipkart Pay",
      "Amazon Pay",
      "Paytm",
      "Others"
    ],
    "Transportation": ["Uber", "Ola", "Rapido", "Others"],
    "Loan": [
      "GPay",
      "PhonePe",
      "CRED",
      "Paytm",
      "Amazon Pay",
      "Flipkart Pay",
      "Others"
    ],
    "Healthcare & Medicine": ["Medicine Stores", "Hospitals", "Others"],
    "Insurance Payment": [
      "GPay",
      "PhonePe",
      "CRED",
      "Paytm",
      "Amazon Pay",
      "Flipkart Pay",
      "Others"
    ],
  };

  @override
  void initState() {
    super.initState();

    amountFocus.addListener(() {
      if (!amountFocus.hasFocus) _formatAmountToTwoDecimals();
    });

    _loadParties();
    // ✅ Unified autofill for both entry and existingEntry
    final e = widget.existingEntry ?? widget.entry;
    if (e != null) {
      entryType = e['entryType'] ?.toString();
      selectedPartyId = e['partyId'].toString();
      final amt = e['amount'];
      if (amt != null) {
        amountController.text =
        (amt is num) ? amt.toStringAsFixed(2) : double.tryParse(amt.toString())?.toStringAsFixed(2) ?? '';
      }

      noteController.text = e['note'];
      mode = e['mode'];
      purpose = e['purpose'];
      platform = e['platform'];
      paymentMethod = e['paymentMethod'];
      methodNameController.text = e['methodName'] ?? '';
      isSettled = e['isSettled'] == true || e['isSettled'] == 1;
      final rawDate = e['date'];
      if (rawDate is Timestamp) {
        selectedDate = rawDate.toDate();
      } else if (rawDate is DateTime) {
        selectedDate = rawDate;
      } else if (rawDate is String) {
        try {
          selectedDate = DateTime.parse(rawDate);
        } catch (_) {
          selectedDate = DateTime.now();
        }
      }

      // 🔹 Custom fields
      if (purpose == "Others" || purpose == "Other Offline Expenses") {
        customPurposeController.text = e['customPurpose'] ?? '';
      }
      if (platform == "Others") {
        customPlatformController.text = e['customPlatform'] ?? '';
      }
      if (paymentMethod == "Others") {
        customPaymentMethodController.text = e['customPaymentMethod'] ?? '';
      }
    }
  }


  Widget dynamicSpacing({bool visible = true, double height = 12}) {
    return visible ? SizedBox(height: height) : const SizedBox.shrink();
  }


  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    methodNameController.dispose();
    customPurposeController.dispose();
    customPlatformController.dispose();
    customPaymentMethodController.dispose();

    entryTypeFocus.dispose();
    partyFocus.dispose();
    amountFocus.dispose();
    dateFocus.dispose();
    modeFocus.dispose();
    purposeFocus.dispose();
    platformFocus.dispose();
    paymentMethodFocus.dispose();
    methodNameFocus.dispose();
    noteFocus.dispose();

    super.dispose();
  }

  void _formatAmountToTwoDecimals() {
    final text = amountController.text.trim();
    if (text.isEmpty) return;
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return;
    final formatted = parsed.toStringAsFixed(2);
    if (formatted != text) {
      final sel = amountController.selection;
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }


  Future<void> _loadParties() async {
    try {
      final firestoreUserId = await _firebaseService.getFirestoreUserId();
      if (firestoreUserId == null) return;

      final rawParties = await _firebaseService.getPartiesByUserId(firestoreUserId);

      setState(() {
        parties = rawParties.map((p) {
          return {
            'partyId': p['partyId'] ?? p['id'] ?? '',
            'name': p['name'] ?? '',
            ...p,
          };
        }).toList();

        // ✅ Set selectedPartyId after party list is loaded
        final e = widget.existingEntry ?? widget.entry;
        if (e != null) {
          selectedPartyId = (e['partyId'] ?? e['party'] ?? e['party_id'])?.toString();
        }
      });
    } catch (e) {
      debugPrint('Error loading parties: $e');
    }
  }


  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return "Amount required";
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount <= 0) return "Enter valid amount";
    return null;
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

  Future<void> _saveEntry() async {
    if (entryType == null ||
        selectedPartyId == null ||
        amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields ⚠️")),
      );
      return;
    }

    final finalPurpose = (purpose == "Others") ? customPurposeController.text.trim() : purpose;
    final finalPlatform = (platform == "Others") ? customPlatformController.text.trim() : platform;
    final finalPaymentMethod = (paymentMethod == "Others") ? customPaymentMethodController.text.trim() : paymentMethod;
    final amountParsed = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;

    final entryData = {
      'entryType': entryType,
      'partyId': selectedPartyId,
      'partyName': _getPartyName(selectedPartyId),
      'amount': amountParsed,
      'remainingAmount': isSettled ? 0 : amountParsed,
      'date': selectedDate,
      'mode': mode,
      'purpose': finalPurpose,
      'platform': finalPlatform,
      'paymentMethod': finalPaymentMethod,
      'methodName': methodNameController.text.trim(),
      'note': noteController.text.trim(),
      'isSettled': isSettled,
      'updatedAt': DateTime.now(),
    };

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.entry == null ? 'Confirm Add Entry' : 'Confirm Update Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💼 Type: ${entryType ?? '-'}'),
            Text('👤 Party: ${_getPartyName(selectedPartyId)}'),
            Text('💰 Amount: ₹${amountParsed.toStringAsFixed(2)}'),
            Text('📅 Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
            if (finalPurpose != null && finalPurpose.isNotEmpty) Text('🎯 Purpose: $finalPurpose'),
            if (finalPlatform != null && finalPlatform.isNotEmpty) Text('🌐 Platform: $finalPlatform'),
            if (finalPaymentMethod != null && finalPaymentMethod.isNotEmpty) Text('💳 Payment: $finalPaymentMethod'),
            if (noteController.text.trim().isNotEmpty) Text('📝 Note: ${noteController.text.trim()}'),
            const SizedBox(height: 8),
            Text('⚖️ Mark as settled: ${isSettled ? "Yes" : "No"}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Yes, Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      String entryId;
      if (widget.entry == null && widget.existingEntry == null) {
        // New entry
        entryId = await _firebaseService.insertEntry(entryData);
      } else {
        // Update existing entry
        final e = widget.existingEntry ?? widget.entry!;
        await _firebaseService.updateEntry(e['entryId'], entryData);
        entryId = e['entryId'];
        if((entryData['entryType'] != e['entryType']
            || entryData['amount'] != e['amount'])
            || entryData['partyId'] != e['partyId']) {
          final tranType = entryData['entryType'] == "Lend"
              ? "DEBIT"
              : "LIABILITY";
          final ledgerData = {
            'to': tranType == "DEBIT" ? selectedPartyId : widget.userId,
            'from': tranType == "DEBIT" ? widget.userId : selectedPartyId,
            'amount': entryData['amount'],
            'tranType': tranType,
            'entryId': entryId,
            'updatedAt': DateTime.now(),
          };
          // Check if ledger exists
          final existingLedgers = await _firebaseService.getLedgerEntries(
            userId: widget.userId,
            entryId: entryId,
          );

          if (existingLedgers.isNotEmpty) {
            final existingLedger = existingLedgers.first; // pick the first one
            final ledgerId = existingLedger['ledgerId'];

            await _firebaseService.updateLedger(ledgerId, ledgerData);
          } else {
            // No existing ledger found → maybe insert a new one
            await _firebaseService.insertLedger(ledgerData);
          }
        }
      }
      // Ledger handling
      if (isSettled) {
        final isBorrow = entryType?.toUpperCase() == 'BORROW';
        final tranType = isBorrow ? 'PAYMENT' : 'CREDIT';
        final ledgerData = {
          'to': isBorrow ? selectedPartyId : widget.userId,
          'from': isBorrow ? widget.userId : selectedPartyId,
          'amount': amountParsed,
          'tranType': tranType,
          'entryId': entryId,
          'updatedAt': DateTime.now(),
        };
        // Check if ledger exists
        final existingLedgers = await _firebaseService.getLedgerEntries(
          userId: widget.userId,
          entryId: entryId,
        );
        if (existingLedgers.isNotEmpty) {
          final existingLedger = existingLedgers.first; // pick the first one
          final ledgerId = existingLedger['ledgerId'];
          await _firebaseService.updateLedger(ledgerId, ledgerData);
        } else {
          // No existing ledger found → maybe insert a new one
          await _firebaseService.insertLedger(ledgerData);
        }
      }
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
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

        // Only pop the page after the dialog is closed
        Navigator.pop(context, {'entryId': entryId, ...entryData});
      }
    } catch (e) {
      debugPrint("Error saving entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to save entry")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPartyName(String? id) {
    if (id == null) return 'Unknown';
    final found = parties.firstWhere(
          (p) => (p['partyId']?.toString() ?? '') == id,
      orElse: () => {'name': 'Unknown'},
    );
    return found['name'] ?? 'Unknown';
  }



  Color _getAccentColor() {
    if (entryType == 'Lend') return Colors.teal.shade900;
    if (entryType == 'Borrow') return Colors.pink.shade900;
    return Colors.black87;
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

// Hide only Payment Method (not platform or details)
  bool get hidePaymentMethod {
    return mode == "Online Expense" &&
        (purpose == "Loan" ||
            purpose == "Recharge/Bill Payments" ||
            purpose == "Insurance Payment");
  }

  @override
  Widget build(BuildContext context) {
    Widget spacing({double height = 12}) => const SizedBox(height: 12);
    final accentColor = _getAccentColor();
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
                  // Main form
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(widget.existingEntry == null ? "Add Entry" : "Edit Entry",
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 18),

                            // Entry Type
                            DropdownButtonFormField<String>(
                              focusNode: entryTypeFocus,
                              value: entryType,
                              decoration: const InputDecoration(
                                labelText: "Entry Type",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.swap_vert),
                              ),
                              items: ["Lend", "Borrow"]
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => entryType = val);
                                // focus party after choosing entryType
                                FocusScope.of(context).requestFocus(partyFocus);
                              },
                              validator: (val) => val == null ? "Select Entry Type" : null,
                            ),
                            const SizedBox(height: 12),

                            // Party dropdown
                            DropdownButtonFormField<String>(
                              value: parties.any((p) => p['partyId']?.toString() == selectedPartyId)
                                  ? selectedPartyId
                                  : null, // <-- avoid invalid initial value
                              decoration: const InputDecoration(
                                labelText: 'Select Party',
                                prefixIcon: Icon(Icons.people),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                ...parties.map(
                                      (p) => DropdownMenuItem(
                                    value: p['partyId']?.toString(),
                                    child: Text(p['name']?.toString() ?? 'Unknown'),
                                  ),
                                ),
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
                            const SizedBox(height: 12),
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
                              validator: validateAmount,
                              onEditingComplete: () {
                                _formatAmountToTwoDecimals();
                                FocusScope.of(context).requestFocus(dateFocus);
                              },
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),

                            // Expense Mode
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
                            const SizedBox(height: 12),
                            // 🔹 Purpose dropdown
                            DropdownButtonFormField<String>(
                              focusNode: purposeFocus,
                              value: (purposeOptions.contains(purpose)) ? purpose : null,
                              decoration: const InputDecoration(
                                labelText: "Purpose",
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: purposeOptions
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
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
                            // 🟣 Custom Purpose (conditionally visible)
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
                            // 🟡 Platform Dropdown
                            if (mode == "Online Expense" && platformOptions.containsKey(purpose)) ...[
                              DropdownButtonFormField<String>(
                                focusNode: platformFocus,
                                value: ((platformOptions[purpose] ?? []).contains(platform)) ? platform : null,
                                decoration: const InputDecoration(
                                  labelText: "Select Platform",
                                  prefixIcon: Icon(Icons.language_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: (platformOptions[purpose] ?? [])
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                    .toList(),
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
                                  (purpose == "Loan" ||
                                      purpose == "Recharge/Bill Payments" ||
                                      purpose == "Insurance Payment")),
                            ),
                            // 🟦 Payment Method
                            if (!(mode == "Online Expense" &&
                                (purpose == "Loan" ||
                                    purpose == "Recharge/Bill Payments" ||
                                    purpose == "Insurance Payment"))) ...[
                              DropdownButtonFormField<String>(
                                focusNode: paymentMethodFocus,
                                value: (paymentMethods.contains(paymentMethod)) ? paymentMethod : null,
                                decoration: const InputDecoration(
                                  labelText: "Select Payment Method",
                                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: paymentMethods
                                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => paymentMethod = val);
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (val != "Others") {
                                      FocusScope.of(context).requestFocus(methodNameFocus);
                                    }
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
                            // Additional Details — show only if Payment Method = UPI
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 20),
                            Card(
                              elevation: 3,
                              color: isSettled ? Colors.green[50] : Colors.red[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: Icon(isSettled ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSettled ? Colors.green : Colors.red),
                                title: const Text("Mark as Settled"),
                                trailing: Switch(
                                  activeColor: Colors.green,
                                  value: isSettled,
                                  onChanged: (v) => setState(() => isSettled = v),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            _isLoading ? const CircularProgressIndicator() : ElevatedButton(
                              onPressed: _saveEntry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade800,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                widget.existingEntry == null ? "Add Entry" : "Update Entry",
                                style: TextStyle(color: Colors.deepPurple.shade50, fontSize: 16),
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
}
