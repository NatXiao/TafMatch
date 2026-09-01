import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/services/salary_model.dart';

void main() {
  late Map<String, dynamic> raw;
  late SalaryModel model;

  setUpAll(() async {
    raw = jsonDecode(
      await File('assets/salary_model.json').readAsString(),
    ) as Map<String, dynamic>;
    model = SalaryModel.fromJson(raw);
  });

  test('the export is complete', () {
    expect(model.optionsFor('Diploma'), isNotNull);
    expect((raw['features'] as List), isNotEmpty);
    expect((raw['examples'] as List), isNotEmpty,
        reason: 'No golden examples: re-run section 6 of notebook 07.');
  });

  test('every input value has a type predict can read', () {
    final example = (raw['examples'] as List).first as Map<String, dynamic>;
    final input = (example['input'] as Map).cast<String, Object?>();

    final unreadable = <String>[];
    input.forEach((field, value) {
      if (value != null && value is! num && value is! String && value is! bool) {
        unreadable.add('$field is a ${value.runtimeType}');
      }
    });

    expect(unreadable, isEmpty, reason: unreadable.join(', '));
  });

  test('reproduces the Python model on every golden example', () {
    final examples = raw['examples'] as List;
    final failures = <String>[];

    for (var i = 0; i < examples.length; i++) {
      final example = examples[i] as Map<String, dynamic>;
      final input = (example['input'] as Map).cast<String, Object?>();
      final expected = (example['expected_chf'] as num).toDouble();
      final actual = model.predict(input);
      final gap = (actual - expected).abs();

      if (gap >= 0.01) {
        failures.add(
          'Example $i: expected ${expected.toStringAsFixed(2)} CHF, '
          'got ${actual.toStringAsFixed(2)} CHF (gap ${gap.toStringAsFixed(2)})\n'
          '  input: ${input.entries.map((e) => '${e.key}=${e.value} '
              '(${e.value.runtimeType})').join(', ')}',
        );
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'The Dart port does not match scikit-learn:\n'
          '${failures.join('\n')}\n'
          'A gap of thousands of CHF means a whole feature is being ignored — '
          'check the types printed above against the numeric branch of predict().',
    );
  });

  test('worstExampleError agrees with the per-example check', () {
    expect(model.worstExampleError(), lessThan(0.01));
  });
}