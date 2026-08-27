import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/job_model.dart';

void main() {
  group('Job', () {
    test('creates a job with required fields', () {
      final job = Job(
        id: 'job-1',
        employerId: 'employer-1',
        title: 'Software Developer',
      );

      expect(job.id, 'job-1');
      expect(job.employerId, 'employer-1');
      expect(job.title, 'Software Developer');
      expect(job.description, '');
      expect(job.address, '');
      expect(job.domainName, '');
      expect(job.degree, '');
      expect(job.languages, '');
      expect(job.salaryChfPerHour, isNull);
      expect(job.workPercentage, isNull);
      expect(job.endDate, isNull);
      expect(job.pictureUrl, '');
      expect(job.status, 'live');
      expect(job.createdAt, isNull);
    });

    test('uses default values for optional fields', () {
      final job = Job(
        id: 'job-1',
        employerId: 'employer-1',
        title: 'Software Developer',
      );

      expect(job.description, '');
      expect(job.address, '');
      expect(job.domainName, '');
      expect(job.degree, '');
      expect(job.languages, '');
      expect(job.pictureUrl, '');
      expect(job.status, 'live');
    });

    test('accepts all optional fields', () {
      final endDate = DateTime(2026, 12, 31);
      final createdAt = DateTime(2026, 8, 27);

      final job = Job(
        id: 'job-1',
        employerId: 'employer-1',
        title: 'Software Developer',
        description: 'Develop Flutter applications.',
        address: 'Lausanne',
        domainName: 'IT',
        degree: 'Bachelor',
        languages: 'French, English',
        salaryChfPerHour: 35.50,
        workPercentage: 80,
        endDate: endDate,
        pictureUrl: 'https://example.com/job.jpg',
        status: 'closed',
        createdAt: createdAt,
      );

      expect(job.id, 'job-1');
      expect(job.employerId, 'employer-1');
      expect(job.title, 'Software Developer');
      expect(job.description, 'Develop Flutter applications.');
      expect(job.address, 'Lausanne');
      expect(job.domainName, 'IT');
      expect(job.degree, 'Bachelor');
      expect(job.languages, 'French, English');
      expect(job.salaryChfPerHour, 35.50);
      expect(job.workPercentage, 80);
      expect(job.endDate, endDate);
      expect(job.pictureUrl, 'https://example.com/job.jpg');
      expect(job.status, 'closed');
      expect(job.createdAt, createdAt);
    });

    test('converts a job to a map', () {
      final endDate = DateTime(2026, 12, 31);

      final job = Job(
        id: 'job-1',
        employerId: 'employer-1',
        title: 'Software Developer',
        description: 'Develop Flutter applications.',
        address: 'Lausanne',
        domainName: 'IT',
        degree: 'Bachelor',
        languages: 'French, English',
        salaryChfPerHour: 35.50,
        workPercentage: 80,
        endDate: endDate,
        pictureUrl: 'https://example.com/job.jpg',
        status: 'live',
      );

      final map = job.toMap();

      expect(map['employerId'], 'employer-1');
      expect(map['title'], 'Software Developer');
      expect(map['description'], 'Develop Flutter applications.');
      expect(map['address'], 'Lausanne');
      expect(map['domainName'], 'IT');
      expect(map['degree'], 'Bachelor');
      expect(map['languages'], 'French, English');
      expect(map['salaryChfPerHour'], 35.50);
      expect(map['workPercentage'], 80);
      expect(map['endDate'], Timestamp.fromDate(endDate));
      expect(map['pictureUrl'], 'https://example.com/job.jpg');
      expect(map['status'], 'live');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('converts null endDate to null in toMap', () {
      final job = Job(
        id: 'job-1',
        employerId: 'employer-1',
        title: 'Software Developer',
      );

      final map = job.toMap();

      expect(map['endDate'], isNull);
    });

    test('creates a job from a complete map', () {
      final endDate = DateTime(2026, 12, 31);
      final createdAt = DateTime(2026, 8, 27);

      final map = {
        'employerId': 'employer-1',
        'title': 'Software Developer',
        'description': 'Develop Flutter applications.',
        'address': 'Lausanne',
        'domainName': 'IT',
        'degree': 'Bachelor',
        'languages': 'French, English',
        'salaryChfPerHour': 35.50,
        'workPercentage': 80,
        'endDate': Timestamp.fromDate(endDate),
        'pictureUrl': 'https://example.com/job.jpg',
        'status': 'closed',
        'createdAt': Timestamp.fromDate(createdAt),
      };

      final job = Job.fromMap('job-1', map);

      expect(job.id, 'job-1');
      expect(job.employerId, 'employer-1');
      expect(job.title, 'Software Developer');
      expect(job.description, 'Develop Flutter applications.');
      expect(job.address, 'Lausanne');
      expect(job.domainName, 'IT');
      expect(job.degree, 'Bachelor');
      expect(job.languages, 'French, English');
      expect(job.salaryChfPerHour, 35.50);
      expect(job.workPercentage, 80);
      expect(job.endDate, endDate);
      expect(job.pictureUrl, 'https://example.com/job.jpg');
      expect(job.status, 'closed');
      expect(job.createdAt, createdAt);
    });

    test('uses default values when map fields are missing', () {
      final job = Job.fromMap(
        'job-1',
        {},
      );

      expect(job.id, 'job-1');
      expect(job.employerId, '');
      expect(job.title, '');
      expect(job.description, '');
      expect(job.address, '');
      expect(job.domainName, '');
      expect(job.degree, '');
      expect(job.languages, '');
      expect(job.salaryChfPerHour, isNull);
      expect(job.workPercentage, isNull);
      expect(job.endDate, isNull);
      expect(job.pictureUrl, '');
      expect(job.status, 'live');
      expect(job.createdAt, isNull);
    });

    test('converts numeric values correctly in fromMap', () {
      final job = Job.fromMap(
        'job-1',
        {
          'employerId': 'employer-1',
          'title': 'Software Developer',
          'salaryChfPerHour': 42,
          'workPercentage': 80.0,
        },
      );

      expect(job.salaryChfPerHour, 42.0);
      expect(job.salaryChfPerHour, isA<double>());
      expect(job.workPercentage, 80);
      expect(job.workPercentage, isA<int>());
    });

    test('converts Timestamp fields to DateTime in fromMap', () {
      final endDate = DateTime(2026, 12, 31);
      final createdAt = DateTime(2026, 8, 27);

      final job = Job.fromMap(
        'job-1',
        {
          'employerId': 'employer-1',
          'title': 'Software Developer',
          'endDate': Timestamp.fromDate(endDate),
          'createdAt': Timestamp.fromDate(createdAt),
        },
      );

      expect(job.endDate, endDate);
      expect(job.createdAt, createdAt);
      expect(job.endDate, isA<DateTime>());
      expect(job.createdAt, isA<DateTime>());
    });
  });
}