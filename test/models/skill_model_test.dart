import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/models/skill_model.dart';

void main() {
  group('Skill', () {
    test('creates a skill with required fields', () {
      final skill = Skill(
        id: 'skill-1',
        name: 'Dart',
      );

      expect(skill.id, 'skill-1');
      expect(skill.name, 'Dart');
    });

    test('converts a skill to a map', () {
      final skill = Skill(
        id: 'skill-1',
        name: 'Dart',
      );

      final map = skill.toMap();

      expect(map['name'], 'Dart');
    });

    test('does not include the id in the map', () {
      final skill = Skill(
        id: 'skill-1',
        name: 'Dart',
      );

      final map = skill.toMap();

      expect(map.containsKey('id'), isFalse);
    });

    test('creates a skill from a complete map', () {
      final skill = Skill.fromMap(
        'skill-1',
        {
          'name': 'Dart',
        },
      );

      expect(skill.id, 'skill-1');
      expect(skill.name, 'Dart');
    });

    test('uses an empty string when name is missing', () {
      final skill = Skill.fromMap(
        'skill-1',
        {},
      );

      expect(skill.id, 'skill-1');
      expect(skill.name, '');
    });

    test('preserves the name when converting to a map and back', () {
      final original = Skill(
        id: 'skill-1',
        name: 'Flutter',
      );

      final restored = Skill.fromMap(
        original.id,
        original.toMap(),
      );

      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });
  });
}