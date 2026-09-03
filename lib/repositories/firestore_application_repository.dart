// Repository for managing application data in Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class FirestoreApplicationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _apps =>
      _db.collection('applications');

  // Apply for a job. The id combines the job and student ids
  Future<void> apply(Application application) {
    final docId = '${application.jobId}_${application.studentId}';
    return _apps.doc(docId).set(application.toMap());
  }

  // Cancel an application (deletes it)
  Future<void> cancel(String applicationId) {
    return _apps.doc(applicationId).delete();
  }
  
  // A student's applications
  Stream<List<Application>> watchByStudent(String studentId) {
    return _apps
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Application.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Applicants for a job posting (employer side)
  Stream<List<Application>> watchByJob(String jobId) {
    return _apps
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Application.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Change the status (accepted, rejected...)
  Future<void> updateStatus(String applicationId, String status) {
    return _apps.doc(applicationId).update({'status': status});
  }
}