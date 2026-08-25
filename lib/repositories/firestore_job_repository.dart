import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class FirestoreJobRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _jobs =>
      _db.collection('jobs');

  // Créer une offre → renvoie l'id généré
  Future<String> create(Job job) async {
    final doc = await _jobs.add(job.toMap());
    return doc.id;
  }

  Future<Job?> getById(String id) async {
    final doc = await _jobs.doc(id).get();
    if (!doc.exists) return null;
    return Job.fromMap(id, doc.data()!);
  }

  // Toutes les offres ouvertes (pour les étudiants)
  Stream<List<Job>> watchLiveJobs() {
    return _jobs
        .where('status', isEqualTo: 'live')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Les offres d'un employeur précis
  Stream<List<Job>> watchByEmployer(String employerId) {
    return _jobs
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> update(String id, Map<String, dynamic> fields) {
    return _jobs.doc(id).update(fields);
  }

  Future<void> delete(String id) {
    return _jobs.doc(id).delete();
  }
}