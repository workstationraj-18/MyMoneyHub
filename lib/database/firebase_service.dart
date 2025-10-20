import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // ========================= COMMON =========================

  Future<String> getCurrentUserID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    return userData?['userID'];
  }

  Future<String> _generateCustomId(String collection) async {
    final snapshot = await _db
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.id;

      final numberPart = RegExp(r'\d+').firstMatch(lastId)?.group(0);
      if (numberPart != null) {
        nextNumber = int.parse(numberPart) + 1;
      }
    }

    String prefix;
    int padLength;

    switch (collection) {
      case 'users':
        prefix = 'USR';
        padLength = 3;
        break;
      case 'entries':
        prefix = 'TRAN';
        padLength = 4;
        break;
      case 'parties':
        prefix = 'PRT';
        padLength = 4;
        break;
      case 'ledger':
        prefix = 'LDGR';
        padLength = 4;
        break;
      default:
        prefix = 'DOC';
        padLength = 3;
    }

    final formatted = '$prefix${nextNumber.toString().padLeft(padLength, '0')}';
    return formatted;
  }

  // ========================= USERS =========================
  Future<String> createUser(String uid, Map<String, dynamic> userData) async {
    final customId = await _generateCustomId('users');

    await _db.collection('users').doc(customId).set({
      ...userData,
      'userId': customId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return customId;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByUid(String uid) async {
    try {
      final snapshot = await _db.collection('users').where('uid', isEqualTo: uid).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } catch (e) {
      debugPrint('❌ getUserByUid error: $e');
      return null;
    }
  }

  Future<String> getUserFullNameByUserId(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 'Unknown';
      final userData = snapshot.docs.first.data();
      return userData['fullName'];
    } catch (e) {
      debugPrint('❌ getUserDataByUserId error: $e');
      return 'Unknown';
    }
  }

// Fetch user document by userId
  Future<Map<String, dynamic>?> getUserDataByUserId(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.data(); // returns Map<String, dynamic>
    } catch (e) {
      debugPrint('❌ getUserDataByUserId error: $e');
      return null;
    }
  }



  // ========================= NOTIFICATIONS =========================
  Future<void> addNotification({
    required String title,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notiRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc();

    await notiRef.set({
      'id': notiRef.id,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🧾 Count entries by settlement status
  Future<int> countEntries({required bool isSettled}) async {
    try {
      final snapshot = await _db
          .collection('entries')
          .where('isSettled', isEqualTo: isSettled)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print("Error counting entries: $e");
      return 0;
    }
  }

  Stream<List<Map<String, dynamic>>> streamEntries({required String userId}) {
    // Return a real-time stream of entries for the given userId
    return FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'entryId': doc.id, // include the document ID
      ...doc.data() as Map<String, dynamic>
    })
        .toList());
  }



  Future<String?> getFirestoreUserId() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return null;

      final userDoc = await _db
          .collection('users')
          .where('uid', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        debugPrint('⚠️ No Firestore user found for uid: ${authUser.uid}');
        return null;
      }

      final id = userDoc.docs.first.id; // example: "USR002"
      debugPrint('✅ getFirestoreUserId => $id');
      return id;
    } catch (e) {
      debugPrint('❌ getFirestoreUserId error: $e');
      return null;
    }
  }



  Future<double> getLiabilityAmount(String userId) async {
    double total = 0.0;
    final snapshot = await FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .where('entryType', isEqualTo: 'BORROW')
        .where('isSettled', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      total += (doc['remainingAmount'] ?? 0).toDouble();
    }
    return total;
  }

  Future<double> getLendingAmount(String userId) async {
    double total = 0.0;
    final snapshot = await FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .where('entryType', isEqualTo: 'LEND')
        .where('isSettled', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      total += (doc['remainingAmount'] ?? 0).toDouble();
    }
    return total;
  }


  // ========================= PARTIES =========================
  Future<String> insertParty(Map<String, dynamic> partyData) async {
    final customId = await _generateCustomId('parties');
    await _db.collection('parties').doc(customId).set({
      ...partyData,
      'partyId': customId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await addNotification(
      title: "New Party Added",
      message: "You added a new party: ${partyData['name'] ?? 'Unknown'}",
    );
    return customId;
  }


  /// 🔹 Fetches parties that belong to this app user (using Firestore userId, not uid)
  Future<List<Map<String, dynamic>>> getPartiesByUserId(String userId) async {
    try {
      final snapshot = await _db
          .collection('parties')
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['partyId'] ?? doc.id,
          'name': data['name'],
          ...data,
        };
      }).toList();

      debugPrint('✅ getPartiesByUserId($userId) => ${list.length} found');
      return list;
    } catch (e) {
      debugPrint('❌ getPartiesByUserId error: $e');
      return [];
    }
  }



  Future<void> updateParty(String partyId,
      Map<String, dynamic> updatedData) async {
    await _db.collection('parties').doc(partyId).update({
      ...updatedData,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addNotification(
      title: "Party Updated",
      message: "You updated party: ${updatedData['name'] ?? 'Unknown'}",
    );
  }

  Future<String?> getPartyNameByPartyId(String partyId) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) throw Exception("User not logged in");
    final userDoc = await getUserByUid(authUser.uid);
    final firestoreUserId = userDoc?.id; // 🔥 use document ID (USR001)

    final parties = await getPartiesByUserId(firestoreUserId!);
    final party = parties.firstWhere(
          (p) => p['partyId'] == partyId,  // since field and doc ID are same
      orElse: () => {},
    );

    // safely return name
    return party.isNotEmpty ? party['name'] : null;
  }


  // ========================= ENTRIES =========================
  Future<String> insertEntry(Map<String, dynamic> entryData) async {
    final customId = await _generateCustomId('entries');
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) throw Exception("User not logged in");

    final userDoc = await getUserByUid(authUser.uid);
    final firestoreUserId = userDoc?.id; // 🔥 use document ID (USR001)
    if (firestoreUserId == null) throw Exception(
        "User not found in users collection");

    await _db.collection('entries').doc(customId).set({
      ...entryData,
      'entryId': customId,
      'userId': firestoreUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addNotification(
      title: "${entryData['type'] ?? 'Entry'} Added",
      message: "₹$entryData[amount] ${entryData['type'] ??
          'Entry'} added for ${entryData['party'] ?? 'Unknown'}",
    );

    return customId;
  }

  Future<List<Map<String, dynamic>>> getEntriesByUserId({required userId}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  Future<void> updateEntry(String entryId,
      Map<String, dynamic> updatedData) async {
    await _db.collection('entries').doc(entryId).update({
      ...updatedData,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addNotification(
      title: "${updatedData['type'] ?? 'Entry'} Updated",
      message:
      "₹${updatedData['amount'] ?? 0} ${updatedData['type'] ??
          'Entry'} updated for ${updatedData['party'] ?? 'Unknown'}",
    );
  }

  Future<void> settleEntry(Map<String, dynamic> entryData) async {
    final entryId = entryData['id'];
    final entryType = entryData['entryType'];
    final amount = entryData['amount'];
    final from = entryData['from'];
    final to = entryData['to'];

    // Step 1: Mark entry as settled
    await FirebaseFirestore.instance.collection('entries').doc(entryId).update({
      'isSettled': true,
      'settledAt': DateTime.now(),
    });

    // Step 2: Add corresponding ledger entry
    final ledgerRef = FirebaseFirestore.instance.collection('ledger').doc();

    String tranType;
    if (entryType == 'BORROW') {
      tranType = 'PAYMENT';
    } else if (entryType == 'LEND') {
      tranType = 'CREDIT';
    } else {
      tranType = 'UNKNOWN';
    }

    await ledgerRef.set({
      'entryId': entryId,
      'amount': amount,
      'tranType': tranType,
      'from': to, // swapped
      'to': from, // swapped
      'createdAt': DateTime.now(),
    });
  }


  // ========================= LEDGER =========================
  Future<String> insertLedger(Map<String, dynamic> ledgerData) async {
    final customId = await _generateCustomId('ledger');
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) throw Exception("User not logged in");
    final userDoc = await getUserByUid(authUser.uid);
    final firestoreUserId = userDoc?.id; // 🔥 use document ID (USR001)
    if (firestoreUserId == null) throw Exception("User not found in users collection");
    await _db.collection('ledger').doc(customId).set({
      ...ledgerData,
      'ledgerId': customId,
      'userId': firestoreUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return customId;
  }

  Future<void> updateLedger(String ledgerId,
      Map<String, dynamic> data) async {
    await _db.collection('ledger').doc(ledgerId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getLedgerEntries({required String userId, String? entryId}) async {
    try {
      // 3️⃣ Fetch ledger entries for this user
      Query query = FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      if (entryId != null && entryId.isNotEmpty) {
        query = query.where('entryId', isEqualTo: entryId);
      }
      final snapshot = await query.get();
      final ledgers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; // ✅ cast to Map<String, dynamic>
        return <String, dynamic>{
          'id': doc.id,
          'from': data['from'],
          'to': data['to'],
          'tranType': data['tranType'],
          'amount': data['amount'],
          'createdAt': data['createdAt'],
          ...data,
        };
      }).toList();
      debugPrint("✅ getLedgerEntries($userId) => ${ledgers.length} records found");
      return ledgers;
    } catch (e, st) {
      debugPrint("❌ getLedgerEntries error: $e\n$st");
      return [];
    }
  }

  Future<void> syncLedger(
      String userId,
      String entryId,
      Map<String, dynamic> entryData,
      bool isSettled, {
        bool isUpdate = false,
      }) async {
    try {
      final entryType = entryData['entryType']?.toString().toUpperCase();
      final amount = entryData['amount'];
      final partyId = entryData['partyId'];

      // Step 0: Find latest reference ledger
      String? referenceLedgerId;
      Query query = FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: userId);

      if (entryId.isNotEmpty) {
        query = query
            .where('entryId', isEqualTo: entryId)
            .orderBy('createdAt', descending: true)
            .limit(1);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        referenceLedgerId = snapshot.docs.first.id;
      }

      // Step 1: Define transaction mappings
      String mainTranType = '';
      String? settleTranType;
      String? mainFrom;
      String? mainTo;
      String? settleFrom;
      String? settleTo;

      if (entryType == 'LEND') {
        mainTranType = 'DEBIT';
        mainFrom = userId;
        mainTo = partyId;

        if (isSettled) {
          settleTranType = 'CREDIT';
          settleFrom = partyId;
          settleTo = userId;
        }
      } else if (entryType == 'BORROW') {
        mainTranType = 'LIABILITY';
        mainFrom = partyId;
        mainTo = userId;

        if (isSettled) {
          settleTranType = 'PAYMENT';
          settleFrom = userId;
          settleTo = partyId;
        }
      }

      // Step 2: Base data
      final baseLedgerData = {
        'entryId': entryId,
        'amount': amount,
        if (referenceLedgerId != null) 'referenceId': referenceLedgerId,
      };

      // Step 3: Add / Edit / Settle handling
      if (!isUpdate) {
        // 🔹 New entry (main)
        final mainLedger = {
          ...baseLedgerData,
          'tranType': mainTranType,
          'from': mainFrom,
          'to': mainTo,
        };
        final mainLedgerId = await insertLedger(mainLedger);
        debugPrint("✅ Ledger inserted (InsertNew): $mainLedgerId");

        // 🔹 If settled immediately, add settle ledger
        if (isSettled && settleTranType != null) {
          final settleLedger = {
            ...baseLedgerData,
            'tranType': settleTranType,
            'from': settleFrom,
            'to': settleTo,
            'referenceId': mainLedgerId, // ✅ fixed
            'updatedAt': FieldValue.serverTimestamp(),
          };
          final settleLedgerId = await insertLedger(settleLedger);
          debugPrint("✅ Ledger inserted (SettleNew): $settleLedgerId");
        }
      } else {
        // 🔹 Settling existing entry
        if (isSettled && settleTranType != null) {
          final settleLedger = {
            ...baseLedgerData,
            'tranType': settleTranType,
            'from': settleFrom,
            'to': settleTo,
            'updatedAt': FieldValue.serverTimestamp(), // ✅ fixed
          };
          final settleLedgerId = await insertLedger(settleLedger);
          debugPrint("✅ Ledger inserted (SettledExisting): $settleLedgerId");
        }else{
          // 🔹 Editing existing entry
          final updatedLedger = {
            ...baseLedgerData,
            'tranType': mainTranType,
            'from': mainFrom,
            'to': mainTo,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          final updatedLedgerId = await insertLedger(updatedLedger);
          debugPrint("✅ Ledger inserted (Edited): $updatedLedgerId");
        }
      }
    } catch (e) {
      debugPrint("❌ Error syncing ledger: $e");
    }
  }









  // ========================= HELPERS =========================
  Future<void> deleteById(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();

    await addNotification(
      title: "Record Deleted",
      message: "A record from $collection was deleted.",
    );
  }

  /// Convenience helpers
  Future<void> deleteParty(String partyId) async {
    await deleteById('parties', partyId);
  }

  Future<void> deleteEntry(String entryId) async {
    await deleteById('entries', entryId);
  }

  Future<void> deleteLedger(String ledgerId) async {
    await deleteById('ledger', ledgerId);
  }
}

