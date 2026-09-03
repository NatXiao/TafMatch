// Application model representing a student's application to a job.
import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String jobId;
  final String studentId;
  final String status;               // "submitted", "reviewed", "accepted", "rejected"
  final DateTime? appliedAt;

  Application({
    required this.id,
    required this.jobId,
    required this.studentId,
    this.status = 'submitted',
    this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'studentId': studentId,
      'status': status,
      'appliedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Application.fromMap(String id, Map<String, dynamic> map) {
    return Application(
      id: id,
      jobId: map['jobId'] ?? '',
      studentId: map['studentId'] ?? '',
      status: map['status'] ?? 'submitted',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate(),
    );
  }
}