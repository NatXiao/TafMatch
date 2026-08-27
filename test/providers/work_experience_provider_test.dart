import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/work_experience_model.dart';
import 'package:taf_match/providers/work_experience_provider.dart';

import '../fakes.dart';

WorkExperience _exp(String id, {String userId = 'user1'}) =>
    WorkExperience(id: id, userId: userId);

void main() {
  late FakeWorkExperienceRepository repository;
  late WorkExperienceProvider provider;

  setUp(() {
    repository = FakeWorkExperienceRepository();
    provider = WorkExperienceProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    repository.dispose();
  });

  // The provider exposes an empty list before any stream emits.
  test('starts with an empty list', () {
    expect(provider.experiences, isEmpty);
  });

  // Listening to a user's experiences fills the list and notifies listeners.
  test('listenToUserExperiences updates the list and notifies', () async {
    final experiences = [_exp('e1'), _exp('e2')];

    var notified = false;
    provider.addListener(() => notified = true);

    provider.listenToUserExperiences('user1');
    repository.emit(experiences);
    await Future<void>.delayed(Duration.zero);

    expect(provider.experiences, experiences);
    expect(notified, isTrue);
  });

  // Starting a new listen cancels the previous subscription without errors.
  test('a new listen cancels the previous subscription', () async {
    provider.listenToUserExperiences('user1');
    provider.listenToUserExperiences('user2');

    repository.emit([_exp('e1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.experiences, hasLength(1));
  });

  // addExperience forwards the uid and the experience to the repository.
  test('addExperience delegates to the repository with uid and experience', () async {
    final exp = _exp('', userId: 'user1');

    await provider.addExperience('user1', exp);

    expect(repository.addCallCount, 1);
    expect(repository.lastAddedUid, 'user1');
    expect(repository.lastAddedExperience, same(exp));
  });

  // deleteExperience forwards the uid and the experience id to the repository.
  test('deleteExperience delegates to the repository with uid and id', () async {
    await provider.deleteExperience('user1', 'exp1');

    expect(repository.deleteCallCount, 1);
    expect(repository.lastDeletedUid, 'user1');
    expect(repository.lastDeletedId, 'exp1');
  });
}