/**
 * Repository for managing application data in Firestore.
 */
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class FirestoreApplicationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _apps =>
      _db.collection('applications');

  // Postuler. L'id combine job + étudiant
  Future<void> apply(Application application) {
    final docId = '${application.jobId}_${application.studentId}';
    return _apps.doc(docId).set(application.toMap());
  }

  // Les candidatures d'un étudiant
  Stream<List<Application>> watchByStudent(String studentId) {
    return _apps
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Application.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Les candidats à une offre (côté employeur)
  Stream<List<Application>> watchByJob(String jobId) {
    return _apps
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Application.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Changer le statut (accepté, rejeté...)
  Future<void> updateStatus(String applicationId, String status) {
    return _apps.doc(applicationId).update({'status': status});
  }
}