import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/review_model.dart';

void main() {
  group('Review', () {
    test('creates a review with required fields', () {
      final review = Review(
        id: 'review-1',
        authorId: 'user-1',
        targetUserId: 'user-2',
        rating: 5,
      );

      expect(review.id, 'review-1');
      expect(review.authorId, 'user-1');
      expect(review.targetUserId, 'user-2');
      expect(review.rating, 5);
      expect(review.comment, '');
      expect(review.createdAt, isNull);
    });

    test('uses empty string as the default comment', () {
      final review = Review(
        id: 'review-1',
        authorId: 'user-1',
        targetUserId: 'user-2',
        rating: 4,
      );

      expect(review.comment, '');
    });

    test('accepts a custom comment', () {
      final review = Review(
        id: 'review-1',
        authorId: 'user-1',
        targetUserId: 'user-2',
        rating: 5,
        comment: 'Excellent experience.',
      );

      expect(review.comment, 'Excellent experience.');
    });

    test('accepts a createdAt date', () {
      final createdAt = DateTime(2026, 8, 27, 14, 30);

      final review = Review(
        id: 'review-1',
        authorId: 'user-1',
        targetUserId: 'user-2',
        rating: 5,
        createdAt: createdAt,
      );

      expect(review.createdAt, createdAt);
    });

    test('converts a review to a map', () {
      final review = Review(
        id: 'review-1',
        authorId: 'user-1',
        targetUserId: 'user-2',
        rating: 5,
        comment: 'Excellent experience.',
      );

      final map = review.toMap();

      expect(map['authorId'], 'user-1');
      expect(map['targetUserId'], 'user-2');
      expect(map['rating'], 5);
      expect(map['comment'], 'Excellent experience.');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('creates a review from a complete map', () {
      final createdAt = DateTime(2026, 8, 27, 14, 30);

      final map = {
        'authorId': 'user-1',
        'targetUserId': 'user-2',
        'rating': 5,
        'comment': 'Excellent experience.',
        'createdAt': Timestamp.fromDate(createdAt),
      };

      final review = Review.fromMap('review-1', map);

      expect(review.id, 'review-1');
      expect(review.authorId, 'user-1');
      expect(review.targetUserId, 'user-2');
      expect(review.rating, 5);
      expect(review.comment, 'Excellent experience.');
      expect(review.createdAt, createdAt);
    });

    test('uses default values when map fields are missing', () {
      final review = Review.fromMap(
        'review-1',
        {},
      );

      expect(review.id, 'review-1');
      expect(review.authorId, '');
      expect(review.targetUserId, '');
      expect(review.rating, 0);
      expect(review.comment, '');
      expect(review.createdAt, isNull);
    });

    test('converts Timestamp to DateTime in fromMap', () {
      final date = DateTime(2026, 8, 27, 14, 30);
      final timestamp = Timestamp.fromDate(date);

      final review = Review.fromMap(
        'review-1',
        {
          'authorId': 'user-1',
          'targetUserId': 'user-2',
          'rating': 4,
          'createdAt': timestamp,
        },
      );

      expect(review.createdAt, date);
      expect(review.createdAt, isA<DateTime>());
    });

    test('converts the rating correctly from an integer', () {
      final review = Review.fromMap(
        'review-1',
        {
          'authorId': 'user-1',
          'targetUserId': 'user-2',
          'rating': 3,
        },
      );

      expect(review.rating, 3);
      expect(review.rating, isA<int>());
    });
  });
}