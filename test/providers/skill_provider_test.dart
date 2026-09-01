import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/skill_model.dart';
import 'package:taf_match/providers/skill_provider.dart';

import '../fakes.dart';

void main() {
  group('SkillProvider', () {
    late FakeSkillRepository repo;
    late SkillProvider provider;

    setUp(() {
      repo = FakeSkillRepository();
      provider = SkillProvider(repo);
    });

    test('starts with empty skills and not loading', () {
      expect(provider.skills, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('loadSkills sets isLoading true then false, and populates skills', () async {
      repo.skillsToReturn = [
        Skill(id: '1', name: 'Dart'),
        Skill(id: '2', name: 'Flutter'),
      ];

      final future = provider.loadSkills();

      // Immediately after calling (before await), loading should already be true.
      expect(provider.isLoading, isTrue);

      await future;

      expect(provider.isLoading, isFalse);
      expect(provider.skills.length, 2);
      expect(provider.skills.first.name, 'Dart');
    });

    test('loadSkills calls repository exactly once per invocation', () async {
      repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];

      await provider.loadSkills();

      expect(repo.getAllCallCount, 1);
    });

    test('notifyListeners is called twice during a successful load (start + end)', () async {
      repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadSkills();

      expect(notifyCount, 2);
    });

    test('loadSkills propagates repository errors and leaves isLoading stuck true', () async {
      repo.getAllError = Exception('firestore unavailable');

      expect(
        () => provider.loadSkills(),
        throwsA(isA<Exception>()),
      );

      // Let the microtask queue settle.
      await Future<void>.delayed(Duration.zero);

      // Current implementation never resets isLoading to false if getAll throws,
      // since the throw happens before the second notifyListeners/assignment.
      expect(provider.isLoading, isTrue);
      expect(provider.skills, isEmpty);
    });

    test('a second successful loadSkills call replaces previous skills entirely', () async {
      repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];
      await provider.loadSkills();
      expect(provider.skills.length, 1);

      repo.skillsToReturn = [
        Skill(id: '2', name: 'Flutter'),
        Skill(id: '3', name: 'Firebase'),
      ];
      await provider.loadSkills();

      expect(provider.skills.length, 2);
      expect(provider.skills.any((s) => s.id == '1'), isFalse);
    });

    test('loadSkills reflects an empty catalog correctly', () async {
      repo.skillsToReturn = [];
      await provider.loadSkills();

      expect(provider.skills, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('overlapping loadSkills calls: second call wins with its own gate', () async {
      // First call gated so it resolves after the second one.
      final firstGate = Completer<List<Skill>>();
      repo.getAllGate = firstGate;

      final firstCall = provider.loadSkills();

      // Release the gate for the *second* call by swapping it before awaiting.
      // Since FakeSkillRepository uses a single gate field, simulate sequential
      // overlapping behavior by completing the first gate with stale data,
      // then immediately issuing a second call with fresh data.
      firstGate.complete([Skill(id: 'stale', name: 'Old')]);
      await firstCall;

      repo.getAllGate = null;
      repo.skillsToReturn = [Skill(id: 'fresh', name: 'New')];
      await provider.loadSkills();

      expect(provider.skills.single.id, 'fresh');
    });

    group('nameForId', () {
      test('returns the matching name when id exists', () async {
        repo.skillsToReturn = [
          Skill(id: '1', name: 'Dart'),
          Skill(id: '2', name: 'Flutter'),
        ];
        await provider.loadSkills();

        expect(provider.nameForId('2'), 'Flutter');
      });

      test('returns the id itself when no skill matches', () async {
        repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];
        await provider.loadSkills();

        expect(provider.nameForId('unknown-id'), 'unknown-id');
      });

      test('returns the id itself when skills list is empty', () {
        expect(provider.nameForId('anything'), 'anything');
      });

      test('returns the first match when duplicate ids exist', () async {
        repo.skillsToReturn = [
          Skill(id: 'dup', name: 'First'),
          Skill(id: 'dup', name: 'Second'),
        ];
        await provider.loadSkills();

        expect(provider.nameForId('dup'), 'First');
      });

      test('is case-sensitive when matching ids', () async {
        repo.skillsToReturn = [Skill(id: 'ABC', name: 'Dart')];
        await provider.loadSkills();

        expect(provider.nameForId('abc'), 'abc'); // falls back to input
      });
    });

    group('namesForIds', () {
      test('maps each id to its resolved name, preserving order', () async {
        repo.skillsToReturn = [
          Skill(id: '1', name: 'Dart'),
          Skill(id: '2', name: 'Flutter'),
          Skill(id: '3', name: 'Firebase'),
        ];
        await provider.loadSkills();

        final result = provider.namesForIds(['3', '1', '2']);

        expect(result, ['Firebase', 'Dart', 'Flutter']);
      });

      test('mixes resolved names and raw fallback ids', () async {
        repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];
        await provider.loadSkills();

        final result = provider.namesForIds(['1', 'missing']);

        expect(result, ['Dart', 'missing']);
      });

      test('returns an empty list for an empty input iterable', () async {
        repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];
        await provider.loadSkills();

        expect(provider.namesForIds(<String>[]), isEmpty);
      });

      test('handles a non-List Iterable (e.g. a Set) correctly', () async {
        repo.skillsToReturn = [
          Skill(id: '1', name: 'Dart'),
          Skill(id: '2', name: 'Flutter'),
        ];
        await provider.loadSkills();

        final ids = {'1', '2'}; // Set<String>
        final result = provider.namesForIds(ids);

        expect(result.toSet(), {'Dart', 'Flutter'});
      });

      test('repeats a name if the same id is requested multiple times', () async {
        repo.skillsToReturn = [Skill(id: '1', name: 'Dart')];
        await provider.loadSkills();

        final result = provider.namesForIds(['1', '1', '1']);

        expect(result, ['Dart', 'Dart', 'Dart']);
      });
    });
  });
}