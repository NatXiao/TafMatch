import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/work_experience_model.dart';

void main() {
  group('WorkExperience', () {
    test('creates a work experience with required fields', () {
      final experience = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
      );

      expect(experience.id, 'experience-1');
      expect(experience.userId, 'user-1');
      expect(experience.jobId, isNull);
    });

    test('accepts a jobId', () {
      final experience = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
        jobId: 'job-1',
      );

      expect(experience.id, 'experience-1');
      expect(experience.userId, 'user-1');
      expect(experience.jobId, 'job-1');
    });

    test('converts a work experience to a map', () {
      final experience = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
        jobId: 'job-1',
      );

      final map = experience.toMap();

      expect(map['userId'], 'user-1');
      expect(map['jobId'], 'job-1');
    });

    test('includes null jobId in the map when no job is linked', () {
      final experience = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
      );

      final map = experience.toMap();

      expect(map['userId'], 'user-1');
      expect(map['jobId'], isNull);
    });

    test('does not include the id in the map', () {
      final experience = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
        jobId: 'job-1',
      );

      final map = experience.toMap();

      expect(map.containsKey('id'), isFalse);
    });

    test('creates a work experience from a complete map', () {
      final experience = WorkExperience.fromMap(
        'experience-1',
        {
          'userId': 'user-1',
          'jobId': 'job-1',
        },
      );

      expect(experience.id, 'experience-1');
      expect(experience.userId, 'user-1');
      expect(experience.jobId, 'job-1');
    });

    test('creates a work experience without a jobId', () {
      final experience = WorkExperience.fromMap(
        'experience-1',
        {
          'userId': 'user-1',
          'jobId': null,
        },
      );

      expect(experience.id, 'experience-1');
      expect(experience.userId, 'user-1');
      expect(experience.jobId, isNull);
    });

    test('preserves values when converting to a map and back', () {
      final original = WorkExperience(
        id: 'experience-1',
        userId: 'user-1',
        jobId: 'job-1',
      );

      final restored = WorkExperience.fromMap(
        original.id,
        original.toMap(),
      );

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.jobId, original.jobId);
    });
  });
}