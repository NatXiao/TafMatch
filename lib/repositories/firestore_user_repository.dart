import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreUserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // A shortcut to the "users" collection
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // CREATE the profile
  Future<void> createProfile(UserModel user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  // READ a profile once
  Future<UserModel?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<UserModel>> getUsersByIds(Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    final users = <UserModel>[];

  for (var index = 0; index < ids.length; index += 30) { // TODO index += 30 ??
      final chunk = ids.sublist(index, (index + 30).clamp(0, ids.length));
      final snapshot =
          await _users.where(FieldPath.documentId, whereIn: chunk).get();
      users.addAll(snapshot.docs.map(
        (doc) => UserModel.fromMap(doc.id, doc.data()),
      ));
    }

    return users;
  }

  // LISTEN to a profile in real time (for a StreamBuilder)
  Stream<UserModel?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(uid, doc.data()!);
    });
  }

  // UPDATE specific fields (e.g. name, address)
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _users.doc(uid).update(fields);
  }

  // ADD a skill to the user
  Future<void> addSkill(String uid, String skill) {
    return _users.doc(uid).update({
      'skills': FieldValue.arrayUnion([skill]),
    });
  }

  // REMOVE a skill
  Future<void> removeSkill(String uid, String skill) {
    return _users.doc(uid).update({
      'skills': FieldValue.arrayRemove([skill]),
    });
  }

  // DELETE the profile
  Future<void> deleteProfile(String uid) {
    return _users.doc(uid).delete();
  }
}
