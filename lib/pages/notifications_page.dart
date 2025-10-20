import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _markAsRead(String notificationId) async {
    await _db
        .collection('users')
        .doc(user!.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _db
        .collection('users')
        .doc(user!.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view notifications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('users')
            .doc(user!.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final isRead = data['isRead'] ?? false;
              final title = data['title'] ?? "Notification";
              final message = data['message'] ?? "";
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Dismissible(
                key: ValueKey(id),
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.done, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Mark Read", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Delete", style: TextStyle(color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.delete, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd && !isRead) {
                    _markAsRead(id);
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    await _deleteNotification(id);
                    return true;
                  }
                  return false;
                },
                child: Card(
                  elevation: 2,
                  color: isRead ? Colors.white : Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      isRead ? Colors.grey.shade300 : Colors.blue.shade600,
                      child: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        if (createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _markAsRead(id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "No notifications yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "You'll see alerts and updates here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}
