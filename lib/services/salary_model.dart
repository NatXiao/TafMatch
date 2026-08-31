import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// Salary model exported by notebook 07.
///
/// The whole model is arithmetic: a weighted sum over encoded features, then
/// expm1 to undo the log target, then clipping to the range seen in training.
class SalaryModel {
  SalaryModel._({
    required double intercept,
    required List<dynamic> features,
    required bool logTarget,
    required double? floor,
    required double? ceiling,
    required this.createdUtc,
    required this.inputSchema,
    required this.examples,
    required this.metrics,
  })  : _intercept = intercept,
        _features = features,
        _logTarget = logTarget,
        _floor = floor,
        _ceiling = ceiling;

  final double _intercept;
  final List<dynamic> _features;
  final bool _logTarget;
  final double? _floor;
  final double? _ceiling;

  /// When the model was exported. Stored alongside every prediction so a value
  /// produced by an older model stays recognisable after a retrain.
  final String createdUtc;

  /// Fields to render on the form, with their options and ranges.
  final List<dynamic> inputSchema;

  /// Input/output pairs produced by scikit-learn, for tests.
  final List<dynamic> examples;

  /// The scores this model earned, for an "about" screen.
  final Map<String, dynamic> metrics;

  static Future<SalaryModel> loadAsset(
      [String asset = 'assets/salary_model.json']) async {
    return SalaryModel.fromJson(
        jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>);
  }

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    final post = json['postprocessing'] as Map<String, dynamic>;
    final clip = post['clip'] as Map<String, dynamic>;
    return SalaryModel._(
      intercept: (json['model']['intercept'] as num).toDouble(),
      features: json['features'] as List<dynamic>,
      logTarget: (post['steps'] as List<dynamic>).contains('expm1'),
      floor: (clip['floor'] as num?)?.toDouble(),
      ceiling: (clip['ceiling'] as num?)?.toDouble(),
      createdUtc: json['created_utc'] as String? ?? '',
      inputSchema: json['input_schema'] as List<dynamic>,
      examples: json['examples'] as List<dynamic>,
      metrics: (json['metrics'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Predicts a yearly gross salary in CHF.
  ///
  /// Missing numeric fields fall back to the value the imputer used during
  /// training. A category outside [inputSchema] contributes nothing, exactly
  /// as the encoder behaved -- so validate dropdowns against the schema rather
  /// than relying on this to signal a mistake.
  double predict(Map<String, Object?> input) {
    var total = _intercept;

    for (final raw in _features) {
      final feature = raw as Map<String, dynamic>;
      final value = input[feature['source'] as String];
      final coef = (feature['coef'] as num).toDouble();

      if (feature['kind'] == 'categorical') {
        final seen = value == null ? null : value.toString();
        if (seen == feature['category']) total += coef;
      }        else {
        final fill = (feature['fill_value'] as num).toDouble();

        final double number;
        if (value == null) {
          number = fill;
        } else if (value is bool) {
          // Le modèle a vu 0/1, jamais true/false : convertir, pas parser.
          number = value ? 1.0 : 0.0;
        } else if (value is num) {
          number = value.toDouble();
        } else {
          // Champs texte : l'illisible est traité comme vide, comme l'imputer.
          number = double.tryParse(value.toString().replaceAll(',', '.')) ?? fill;
        }

        final mean = (feature['mean'] as num).toDouble();
        final scale = (feature['scale'] as num).toDouble();
        total += coef * (number - mean) / scale;
      }
    }

    var prediction = _logTarget ? math.exp(total) - 1.0 : total;
    if (_floor != null) prediction = math.max(prediction, _floor!);
    if (_ceiling != null) prediction = math.min(prediction, _ceiling!);
    return prediction;
  }

  /// Worst gap in CHF between [predict] and the embedded golden examples.
  /// Anything above a centime means the port drifted from the Python model.
  double worstExampleError() {
    var worst = 0.0;
    for (final raw in examples) {
      final example = raw as Map<String, dynamic>;
      final expected = (example['expected_chf'] as num).toDouble();
      final actual = predict((example['input'] as Map).cast<String, Object?>());
      worst = math.max(worst, (actual - expected).abs());
    }
    return worst;
  }

  /// Categories the model knows for a given field, or null when the field is
  /// numeric or absent. Use it to build dropdowns, or to check existing ones.
  List<String>? optionsFor(String field) {
    for (final raw in inputSchema) {
      final entry = raw as Map<String, dynamic>;
      if (entry['name'] == field && entry['kind'] == 'categorical') {
        return (entry['options'] as List).map((o) => o.toString()).toList();
      }
    }
    return null;
  }
}