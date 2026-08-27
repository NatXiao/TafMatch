import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreUserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Un raccourci vers la collection "users"
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // CRÉER le profil
  Future<void> createProfile(UserModel user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  // LIRE un profil une seule fois
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

  // ÉCOUTER un profil en temps réel (pour un StreamBuilder)
  Stream<UserModel?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(uid, doc.data()!);
    });
  }

  // METTRE À JOUR quelques champs (ex. nom, adresse)
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _users.doc(uid).update(fields);
  }

  // AJOUTER un skill à l'utilisateur
  Future<void> addSkill(String uid, String skill) {
    return _users.doc(uid).update({
      'skills': FieldValue.arrayUnion([skill]),
    });
  }

  // RETIRER un skill
  Future<void> removeSkill(String uid, String skill) {
    return _users.doc(uid).update({
      'skills': FieldValue.arrayRemove([skill]),
    });
  }

  // SUPPRIMER le profil
  Future<void> deleteProfile(String uid) {
    return _users.doc(uid).delete();
  }
}
