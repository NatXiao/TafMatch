import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/services/salary_model.dart';

/// Adapts the posting form to the 13 columns the exported model expects.
///
/// The form collects far more than the model uses -- title, description,
/// address, photo, dates. None of that reaches [SalaryModel.predict]: the maps
/// built here contain the model's columns and nothing else, under the exact
/// names used during training.
///
/// Formats matter as much as names. The pipeline saw booleans as 0/1, never as
/// `true`/`false`, and language flags as numbers rather than as a list, so the
/// conversion happens here rather than being left to the caller.
class SalaryEstimator {
  SalaryEstimator(this.model);

  final SalaryModel model;

  /// Assumptions for turning a yearly salary into an hourly rate. They are a
  /// convention of this app, not something the model learned -- adjust them
  /// here if yours differ.
  static const double weeklyHours = 42;
  static const double weeksPerYear = 52;

  /// Languages the model actually has a column for. `German` is on the form
  /// but not in the reduced feature set: notebook 06 dropped it, so it stays
  /// in the posting and simply plays no part in the estimate.
  static const List<String> modelledLanguages = ['English', 'French', 'Italian'];

  /// Estimated yearly gross salary, in CHF, from the raw form state.
  ///
  /// Returns null when a required dropdown is still empty -- an estimate built
  /// on missing categories would look plausible and mean nothing.
  double? annualFromForm({
    required String? diploma,
    required String? role,
    required String? industry,
    required String? canton,
    required String? companySize,
    required String experienceMin,
    required String experienceMax,
    required String workloadPercent,
    required String holidays,
    required bool isPermanent,
    required List<String> languages,
  }) {
    if (diploma == null || diploma.isEmpty) return null;
    if (role == null || role.isEmpty) return null;
    if (industry == null || industry.isEmpty) return null;
    if (canton == null || canton.isEmpty) return null;
    if (companySize == null || companySize.isEmpty) return null;

    return model.predict({
      // Categorical: the string has to match a category seen in training,
      // otherwise the encoder contributes zero without complaining.
      'Diploma': diploma,
      'Role': role,
      'Industry': industry,
      'Canton': canton,
      'CompanySize': companySize,

      // Numeric: text fields hand back strings, so parse with a sensible
      // fallback rather than throwing while the user is still typing.
      'ExperienceMin': _toDouble(experienceMin, 0),
      'ExperienceMax': _toDouble(experienceMax, 0),
      'WorkloadPercent': _toDouble(workloadPercent, 100),
      'Holidays': _toDouble(holidays, 25),

      // Booleans and flags: the model saw 0/1.
      'IsPermanent': isPermanent ? 1 : 0,
      'Languages_English': languages.contains('English') ? 1 : 0,
      'Languages_French': languages.contains('French') ? 1 : 0,
      'Languages_Italian': languages.contains('Italian') ? 1 : 0,
    });
  }

  /// Same estimate for a posting already stored in Firestore.
  ///
  /// Useful to re-score an old offer, or to compare what an employer entered
  /// against what the model would have suggested.
  double annualForJob(Job job) => model.predict({
        'Diploma': job.diploma,
        'Role': job.role,
        'Industry': job.industry,
        'Canton': job.canton,
        'CompanySize': job.companySize,
        'ExperienceMin': job.experienceMin,
        'ExperienceMax': job.experienceMax,
        'WorkloadPercent': job.workloadPercent,
        'Holidays': job.holidays,
        'IsPermanent': job.isPermanent ? 1 : 0,
        'Languages_English': job.languagesEnglish,
        'Languages_French': job.languagesFrench,
        'Languages_Italian': job.languagesItalian,
      });

  /// Hourly rate implied by a yearly salary at a given workload.
  double hourlyFromAnnual(double annualChf, double workloadPercent) {
    final worked = weeksPerYear * weeklyHours * (workloadPercent / 100);
    return worked <= 0 ? 0 : annualChf / worked;
  }

  /// Values offered by the form that the model has never seen, and will
  /// therefore score as zero. Call it once in debug with the dropdown lists:
  /// an empty result means the form and the model share a vocabulary.
  List<String> unknownValues(Map<String, List<String>> formOptions) {
    final problems = <String>[];

    formOptions.forEach((field, offered) {
      final known = model.optionsFor(field);
      if (known == null) {
        problems.add('$field is not a categorical column of the model');
        return;
      }
      final unseen = offered.where((o) => !known.contains(o)).toList();
      if (unseen.isNotEmpty) {
        problems.add('$field: ${unseen.join(", ")} — known: ${known.join(", ")}');
      }
    });

    return problems;
  }

  static double _toDouble(String raw, double fallback) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? fallback;
}