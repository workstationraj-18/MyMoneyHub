import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========================= USERS =========================
  /// Create or update a user document
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
  }

  /// Get user details by Firebase Auth UID
  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ========================= PARTIES =========================
  /// Add a new party
  Future<String> insertParty(Map<String, dynamic> partyData) async {
    final ref = await _db.collection('parties').add({
      ...partyData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id; // Return doc ID
  }

  /// Get all parties for a specific user (optional: userId filter)
  Future<List<Map<String, dynamic>>> getAllParties({String? userId}) async {
    Query query = _db.collection('parties');
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => {'partyId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  /// Update an existing party by ID
  Future<void> updateParty(String partyId, Map<String, dynamic> updatedData) async {
    await _db.collection('parties').doc(partyId).update({
      ...updatedData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get a single party by ID
  Future<Map<String, dynamic>?> getPartyById(String partyId) async {
    final doc = await _db.collection('parties').doc(partyId).get();
    if (!doc.exists) return null;
    return {'partyId': doc.id, ...doc.data() as Map<String, dynamic>};
  }


  // ========================= ENTRIES =========================
  /// Insert a new entry
  Future<String> insertEntry(Map<String, dynamic> entryData) async {
    final ref = await _db.collection('entries').add({
      ...entryData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Update an existing entry
  Future<void> updateEntry(String entryId, Map<String, dynamic> updatedData) async {
    await _db.collection('entries').doc(entryId).update(updatedData);
  }

  /// Get entries (filtered by userId, or all)
  Future<List<Map<String, dynamic>>> getEntries({String? userId}) async {
    Query query = _db.collection('entries');
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => {'entryId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  // ========================= LEDGER =========================
  /// Add a ledger entry
  Future<String> insertLedger(Map<String, dynamic> ledgerData) async {
    final ref = await _db.collection('ledger').add({
      ...ledgerData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Get ledger entries for a user
  Future<List<Map<String, dynamic>>> getLedgerEntries({String? userId}) async {
    Query query = _db.collection('ledger');
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => {'ledgerId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  // ========================= HELPERS =========================
  /// Delete any document by ID
  Future<void> deleteById(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }
}
