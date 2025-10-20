import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_service.dart';
import '../widgets/app_ribbon.dart';

class AddPartyPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? party; // For editing existing party

  const AddPartyPage({super.key, required this.userId, this.party});

  @override
  State<AddPartyPage> createState() => _AddPartyPageState();
}

class _AddPartyPageState extends State<AddPartyPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? gender;
  String? relation;
  String? initial;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.party != null) {
      final fullName = widget.party!['name'] ?? '';
      final parts = fullName.split(' ');
      if (parts.length > 1) {
        initial = parts.first;
        nameController.text = parts.skip(1).join(' ');
      }
      phoneController.text = widget.party!['phone'] ?? '';
      emailController.text = widget.party!['email'] ?? '';
      gender = widget.party!['gender'];
      relation = widget.party!['relation'];
    }
    nameController.addListener(() {
      final text = nameController.text;
      final capitalized = text
          .split(' ')
          .map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
          .join(' ');
      if (text != capitalized) {
        nameController.value = nameController.value.copyWith(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
          composing: TextRange.empty,
        );
      }
    });
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Name is required";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) return "Only letters allowed";
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone required";
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return "Enter valid 10-digit phone";
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Invalid email";
    }
    return null;
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    final fullNameWithInitial =
    "${initial ?? ''} ${nameController.text.trim()}".trim();

    // 🟣 Step 1: Confirm before saving
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.party == null
                  ? 'Are you sure you want to add this party?'
                  : 'Are you sure you want to update this party?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('👤 Name: $fullNameWithInitial'),
            Text('📞 Phone: ${phoneController.text.trim()}'),
            if (emailController.text.isNotEmpty)
              Text('✉️ Email: ${emailController.text.trim()}'),
            if (relation != null) Text('🤝 Relation: $relation'),
            if (gender != null) Text('⚧ Gender: $gender'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.indigo)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Yes, Save',style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSave != true) return; // user canceled

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw Exception("User not logged in");

      final userDoc = await _firebaseService.getUserByUid(authUser.uid);
      final firestoreUserId = userDoc?.id; // 🔥 use document ID (USR001)
      if (firestoreUserId == null) throw Exception("User not found in users collection");

      final partyData = {
        'name': fullNameWithInitial,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'gender': gender,
        'relation': relation,
        'userId': firestoreUserId, // ✅ stores like USR001
      };

      String newPartyId;
      if (widget.party == null) {
        // 🟢 insertParty() should return the newly created document ID (partyId)
        newPartyId = await _firebaseService.insertParty(partyData);
      } else {
        newPartyId = widget.party!['partyId'];
        await _firebaseService.updateParty(newPartyId, partyData);
      }

      if (!mounted) return;

      // 🟢 Step 2: Success popup with summary
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.party == null
                    ? 'Party added successfully!'
                    : 'Party updated successfully!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('👤 Name: $fullNameWithInitial'),
              Text('📞 Phone: ${phoneController.text.trim()}'),
              if (relation != null) Text('🤝 Relation: $relation'),
              if (gender != null) Text('⚧ Gender: $gender'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

// ✅ Return new party info to previous page
      Navigator.pop(context, {
        'partyId': newPartyId,
        'name': fullNameWithInitial,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'gender': gender,
        'relation': relation,
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        bool readOnly = false,
        TextInputType? keyboardType,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        String? prefixText,
        TextCapitalization textCapitalization = TextCapitalization.none, // 👈 Add this default
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppRibbon(context, userId: widget.userId),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        widget.party == null ? "Add Party" : "Edit Party",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: initial,
                              decoration: const InputDecoration(
                                labelText: 'Initial',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              items: ['Mr.', 'Ms.', 'Mrs.', 'Dr.']
                                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  initial = val;
                                  // Optional auto gender mapping
                                  if (val == 'Mr.') gender = 'Male';
                                  else if (val == 'Ms.' || val == 'Mrs.') gender = 'Female';
                                  else gender = 'Other';
                                });
                              },
                              validator: (val) => val == null ? 'Select initial' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 8,
                            child: _buildTextField(
                              nameController,
                              "Name",
                              Icons.person,
                              validator: validateName,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        phoneController,
                        "Phone",
                        Icons.phone,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: validatePhone,
                        prefixText: "+91 "
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        emailController,
                        "Email (Optional)",
                        Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setState(() => gender = val),
                        validator: (val) => val == null ? 'Select gender' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: relation,
                        decoration: const InputDecoration(
                          labelText: 'Relation',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Family', 'Cousin', 'Friend', 'Relative', 'Business', 'Other']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) => setState(() => relation = val),
                        validator: (val) => val == null ? 'Select relation' : null,
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null)
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _saveParty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.party == null ? 'Add Party' : 'Update Party',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
