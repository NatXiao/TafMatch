import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_experience_model.dart';

class FirestoreWorkExperienceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // The subcollection of a specific user
  CollectionReference<Map<String, dynamic>> _experiencesOf(String uid) =>
      _db.collection('users').doc(uid).collection('workExperiences');

  Future<void> add(String uid, WorkExperience experience) {
    return _experiencesOf(uid).add(experience.toMap());
  }

  // A user's work experiences
  Stream<List<WorkExperience>> watchForUser(String uid) {
    return _experiencesOf(uid).snapshots().map((snap) => snap.docs
        .map((doc) => WorkExperience.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> delete(String uid, String experienceId) {
    return _experiencesOf(uid).doc(experienceId).delete();
  }
}