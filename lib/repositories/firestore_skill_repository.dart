import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_model.dart';

class FirestoreSkillRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _skills =>
      _db.collection('skills');

  // Lire tout le catalogue
  Future<List<Skill>> getAll() async {
    final snapshot = await _skills.get();
    return snapshot.docs
        .map((doc) => Skill.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Remplir le catalogue une seule fois
  Future<void> seed(List<String> names) async {
    for (final name in names) {
      await _skills.add({'name': name});
    }
  }
}