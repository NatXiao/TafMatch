import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/skill_model.dart';
import 'package:taf_match/providers/skill_provider.dart';

import '../fakes.dart';

Skill _skill(String id) => Skill(id: id, name: 'Skill $id');

void main() {
  late FakeSkillRepository repository;
  late SkillProvider provider;

  setUp(() {
    repository = FakeSkillRepository();
    provider = SkillProvider(repository);
  });

  

  // The provider starts empty and not loading.
  test('starts empty and not loading', () {
    expect(provider.skills, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  // loadSkills stores the skills returned by the repository.
  test('loadSkills stores the loaded skills', () async {
    repository.skillsToReturn = [_skill('1'), _skill('2'), _skill('3')];

    await provider.loadSkills();

    expect(provider.skills, hasLength(3));
    expect(provider.skills.map((s) => s.id), containsAll(['1', '2', '3']));
    expect(provider.isLoading, isFalse);
  });

  // loadSkills calls the repository exactly once.
  test('loadSkills calls the repository once', () async {
    await provider.loadSkills();

    expect(repository.getAllCallCount, 1);
  });

  // isLoading is true while the skills are being loaded.
  test('loadSkills sets isLoading to true while loading', () async {
    repository.getAllGate = Completer<List<Skill>>();

    final future = provider.loadSkills();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isTrue);

    repository.getAllGate!.complete([_skill('1')]);
    await future;

    expect(provider.isLoading, isFalse);
  });

  // A second load replaces the skills from the first one.
  test('loadSkills replaces the previous skills', () async {
    repository.skillsToReturn = [_skill('1')];
    await provider.loadSkills();
    expect(provider.skills, hasLength(1));

    repository.skillsToReturn = [_skill('2'), _skill('3')];
    await provider.loadSkills();

    expect(provider.skills, hasLength(2));
    expect(provider.skills.map((s) => s.id), containsAll(['2', '3']));
  });
}