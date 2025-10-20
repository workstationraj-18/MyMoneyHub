import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_ribbon.dart';
import 'add_party_page.dart';
import '../database/firebase_service.dart';

class ViewPartiesPage extends StatefulWidget {
  final String userId;
  const ViewPartiesPage({required this.userId, super.key});
  @override
  State<ViewPartiesPage> createState() => _ViewPartiesPageState();
}

class _ViewPartiesPageState extends State<ViewPartiesPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await _firebaseService.getCurrentUserID();
    setState(() => userId = id);
  }
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _deleteParty(String id) async {
    try {
      await _firebaseService.deleteParty(id);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Party deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: buildAppRibbon(context, userId: widget.userId),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parties')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No parties found",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final parties = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parties.length,
            itemBuilder: (context, index) {
              final party = parties[index].data() as Map<String, dynamic>;
              final id = parties[index].id;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    party['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (party['relation'] != null &&
                          party['relation'].toString().isNotEmpty)
                        Text(party['relation']),
                      Text("+91 ${party['phone'] ?? 'N/A'}"),
                      if (party['email'] != null &&
                          party['email'].toString().isNotEmpty)
                        Text(party['email']),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.edit, color: Colors.green, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPartyPage(
                                userId: widget.userId,
                                party: {
                                  "id": id,
                                  "name": party['name'],
                                  "relation": party['relation'],
                                  "gender": party['gender'],
                                  "phone": party['phone'],
                                  "email": party['email'],
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red, size: 22),
                        onPressed: () async {
                          final confirmed = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Party"),
                              content: const Text(
                                  "Are you sure you want to delete this party?"),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            _deleteParty(id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
