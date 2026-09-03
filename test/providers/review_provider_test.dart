import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/review_model.dart';
import 'package:taf_match/providers/review_provider.dart';

import '../fakes.dart';

Review _review(String id, {String targetUserId = 'user1'}) => Review(
      id: id,
      authorId: 'author1',
      targetUserId: targetUserId,
      rating: 5,
      comment: 'Great',
    );
    
void main() {
  late FakeReviewRepository repository;
  late ReviewProvider provider;

  setUp(() {
    repository = FakeReviewRepository();
    provider = ReviewProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    repository.dispose();
  });

  // The provider exposes an empty list before any stream emits.
  test('starts with an empty list', () {
    expect(provider.reviews, isEmpty);
  });

  // Listening to a user's reviews fills the list and notifies listeners.
  test('listenToUserReviews updates the list and notifies', () async {
    final reviews = [_review('r1'), _review('r2')];

    var notified = false;
    provider.addListener(() => notified = true);

    provider.listenToUserReviews('user1');
    repository.emit(reviews);
    await Future<void>.delayed(Duration.zero);

    expect(provider.reviews, reviews);
    expect(notified, isTrue);
  });

  // Starting a new listen cancels the previous subscription without errors.
  test('a new listen cancels the previous subscription', () async {
    provider.listenToUserReviews('user1');
    provider.listenToUserReviews('user2');

    repository.emit([_review('r1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.reviews, hasLength(1));
  });

  // addReview forwards the review to the repository once.
  test('addReview delegates to the repository with the right review', () async {
    final review = _review('');

    await provider.addReview(review);

    expect(repository.createCallCount, 1);
    expect(repository.lastCreatedReview, same(review));
  });

  // deleteReview forwards the given id to the repository.
  test('deleteReview delegates to the repository with the right id', () async {
    await provider.deleteReview('r1');

    expect(repository.lastDeletedId, 'r1');
  });
}