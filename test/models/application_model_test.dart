import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/application_model.dart';

void main() {
  group('Application', () {
    test('creates an application with required fields', () {
      final application = Application(
        id: 'application-1',
        jobId: 'job-1',
        studentId: 'student-1',
      );

      expect(application.id, 'application-1');
      expect(application.jobId, 'job-1');
      expect(application.studentId, 'student-1');
      expect(application.status, 'submitted');
      expect(application.appliedAt, isNull);
    });

    test('uses submitted as the default status', () {
      final application = Application(
        id: 'application-1',
        jobId: 'job-1',
        studentId: 'student-1',
      );

      expect(application.status, 'submitted');
    });

    test('accepts a custom status', () {
      final application = Application(
        id: 'application-1',
        jobId: 'job-1',
        studentId: 'student-1',
        status: 'accepted',
      );

      expect(application.status, 'accepted');
    });

    test('accepts an appliedAt date', () {
      final appliedAt = DateTime(2026, 8, 27, 14, 30);

      final application = Application(
        id: 'application-1',
        jobId: 'job-1',
        studentId: 'student-1',
        appliedAt: appliedAt,
      );

      expect(application.appliedAt, appliedAt);
    });

    test('converts application to a map', () {
      final application = Application(
        id: 'application-1',
        jobId: 'job-1',
        studentId: 'student-1',
        status: 'reviewed',
      );

      final map = application.toMap();

      expect(map['jobId'], 'job-1');
      expect(map['studentId'], 'student-1');
      expect(map['status'], 'reviewed');
      expect(map['appliedAt'], isA<FieldValue>());
    });

    test('creates an application from a complete map', () {
      final timestamp = Timestamp.fromDate(
        DateTime(2026, 8, 27, 14, 30),
      );

      final application = Application.fromMap(
        'application-1',
        {
          'jobId': 'job-1',
          'studentId': 'student-1',
          'status': 'reviewed',
          'appliedAt': timestamp,
        },
      );

      expect(application.id, 'application-1');
      expect(application.jobId, 'job-1');
      expect(application.studentId, 'student-1');
      expect(application.status, 'reviewed');
      expect(application.appliedAt, timestamp.toDate());
    });

    test('uses default values when map fields are missing', () {
      final application = Application.fromMap(
        'application-1',
        {},
      );

      expect(application.id, 'application-1');
      expect(application.jobId, '');
      expect(application.studentId, '');
      expect(application.status, 'submitted');
      expect(application.appliedAt, isNull);
    });

    test('converts Timestamp to DateTime in fromMap', () {
      final date = DateTime(2026, 8, 27, 14, 30);
      final timestamp = Timestamp.fromDate(date);

      final application = Application.fromMap(
        'application-1',
        {
          'jobId': 'job-1',
          'studentId': 'student-1',
          'appliedAt': timestamp,
        },
      );

      expect(application.appliedAt, date);
    });
  });
}