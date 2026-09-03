import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/services/address_lookup.dart';
import 'package:taf_match/services/salary_estimator.dart';

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class NewPostingScreen extends StatefulWidget {
  const NewPostingScreen({super.key, this.addressLookup});

  final AddressLookup? addressLookup;

  @override
  State<NewPostingScreen> createState() => NewPostingScreenState();
}

class NewPostingScreenState extends State<NewPostingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _salary = TextEditingController();
  final _workTime = TextEditingController(text: '100');
  final _endDateField = TextEditingController();

  final _experienceMin = TextEditingController(text: '0');
  final _experienceMax = TextEditingController(text: '0');
  final _holidays = TextEditingController(text: '25');

  final _contractStartDateField = TextEditingController();
  final _contractEndDateField = TextEditingController();

  final List<String> _languages = [];

  DateTime? _endDate;
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;

  String? _degree;
  String? _domains;
  String? _role = 'Junior';
  String? _companySize = 'Startup (<50)';
  String? _canton;

  bool _saving = false;
  final _picker = ImagePicker();

  /// Last estimate produced by the model, in CHF per year. Null while a
  /// required dropdown is still empty.
  double? _estimate;
  String? _autoSalary;

  bool _writingSalary = false;

 late  final _addressLookup = widget.addressLookup ?? AddressLookup();
  Timer? _addressDebounce;
  List<AddressSuggestion> _addressSuggestions = const [];

  /// 400 ms sans frappe avant d'interroger l'API: swisstopo demande
  /// explicitement d'eviter les requetes a haute intensite.
  void _onAddressChanged(String value) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _addressLookup.search(value);
      if (mounted) setState(() => _addressSuggestions = results);
    });
  }

  /// Remplit l'adresse et, quand l'API l'a fourni, le canton.
  void _pickAddress(AddressSuggestion suggestion) {
    setState(() {
      _address.text = suggestion.label;
      if (suggestion.canton.isNotEmpty) _canton = suggestion.canton;
      _addressSuggestions = const [];
    });
    FocusScope.of(context).unfocus();
    _recomputeEstimate(); // le canton pese lourd dans le modele
  }

  // ==================== FIN DU BLOC 1 ====================

  /// The estimate brought down to an hourly rate, at the workload entered.
  ///
  /// Same conversion as the one that pre-fills the salary field, so the box
  /// and the field always show the same number until the employer edits it.
  double? get _estimateHourly {
    final annual = _estimate;
    if (annual == null) return null;
    final workload =
        double.tryParse(_workTime.text.trim().replaceAll(',', '.')) ?? 100;
    return context.read<SalaryEstimator>().hourlyFromAnnual(annual, workload);
  }

  String? _pictureUrl;
  bool _uploadingPhoto = false;

  // IsPermanent depends on the contract dates, not the posting expiration date.
  bool get _isPermanent =>
      _contractStartDate != null && _contractEndDate == null;

  /// Feeds the model the 13 columns it was trained on, and nothing else.
  /// The form collects more than that; the estimator drops the rest and
  /// converts each value to the format the pipeline saw.
  double? _computeAnnual() {
    return context.read<SalaryEstimator>().annualFromForm(
          diploma: _degree,
          role: _role,
          industry: _domains,
          canton: _canton,
          companySize: _companySize,
          experienceMin: _experienceMin.text,
          experienceMax: _experienceMax.text,
          workloadPercent: _workTime.text,
          holidays: _holidays.text,
          isPermanent: _isPermanent,
          languages: _languages,
        );
  }

  /// Refreshes the displayed estimate and pre-fills the salary field.
  ///
  /// Writing into `_salary` re-triggers `Form.onChanged`; the equality guard
  /// below makes the second pass a no-op, so this does not loop.
  void _recomputeEstimate() {
    if (_writingSalary) return;

    final annual = _computeAnnual();
    if (annual != _estimate) setState(() => _estimate = annual);
    if (annual == null) return;
    if (_salary.text.isNotEmpty && _salary.text != _autoSalary) return;

    final estimator = context.read<SalaryEstimator>();
    final workload = double.tryParse(
          _workTime.text.trim().replaceAll(',', '.'),
        ) ??
        100;
    final hourly =
        estimator.hourlyFromAnnual(annual, workload).toStringAsFixed(2);

      if (_salary.text == hourly) return;

    _writingSalary = true;
    try {
      _salary.text = hourly;
      _autoSalary = hourly;
    } finally {
      _writingSalary = false;
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();   // BLOC 1
    _addressLookup.dispose();     // BLOC 1
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _salary.dispose();
    _workTime.dispose();
    _endDateField.dispose();

    _experienceMin.dispose();
    _experienceMax.dispose();
    _holidays.dispose();
    _contractStartDateField.dispose();
    _contractEndDateField.dispose();

    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _endDateField.text = _shortDate(picked);
      });
    }
  }

  Future<void> _pickContractStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _contractStartDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _contractStartDate = picked;
        _contractStartDateField.text = _shortDate(picked);
      });
      _recomputeEstimate();
    }
  }

  Future<void> _pickContractEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEndDate ?? _contractStartDate ?? now,
      firstDate: _contractStartDate ?? now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _contractEndDate = picked;
        _contractEndDateField.text = _shortDate(picked);
      });
      _recomputeEstimate();
    }
  }

  Future<void> _pickPhoto() async {
    final imageRepository = context.read<ImageStorageRepository>();

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final Uint8List bytes = await picked.readAsBytes();

      final url = await imageRepository.uploadImage(
        bytes,
        picked.name,
      );

      if (!mounted) return;

      setState(() => _pictureUrl = url);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image upload failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final employerId = context.read<AuthProvider>().user?.uid ?? '';

    // Recomputed here rather than reusing _estimate: the displayed value could
    // be one edit behind, and this is the number that gets stored.
    final predicted = _computeAnnual();
    final modelVersion = context.read<SalaryEstimator>().model.createdUtc;

    final job = Job(
      id: '',
      employerId: employerId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      address: _address.text.trim(),
      domainName: _domains?.trim() ?? '',
      degree: _degree?.trim() ?? '',
      languages: _languages.join(', '),
      salaryChfPerHour: double.tryParse(
        _salary.text.replaceAll(',', '.'),
      ),
      workPercentage: int.tryParse(
        _workTime.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        ),
      ),
      pictureUrl: _pictureUrl ?? '',
      endDate: _endDate,

      // Les deux dates sont maintenant stockees: c'est d'elles que Job deduit
      // isPermanent, au lieu de le figer a la publication.
      contractStartDate: _contractStartDate,
      contractEndDate: _contractEndDate,


      // Seules les saisies sans equivalent ailleurs sont passees ici.
      // industry, diploma, workloadPercent, isPermanent et les trois
      // Languages_* sont des getters de Job: ils se deduisent de domainName,
      // degree, workPercentage, des dates de contrat et de languages.
      experienceMin: double.parse(_experienceMin.text),
      experienceMax: double.parse(_experienceMax.text),
      companySize: _companySize ?? 'Startup (<50)',
      canton: _canton ?? '',
      role: _role ?? 'Junior',
      holidays: double.parse(_holidays.text),

      predictedSalaryChf: predicted,
      predictionModelVersion: modelVersion,
    );

    try {
      await context.read<JobProvider>().createJob(job);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not publish: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                22,
                12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: colors.text,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text(
                    'New posting',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                // Fires on every field and dropdown change; the date pickers
                // and the language chips are not form fields, so they call
                // _recomputeEstimate() themselves.
                onChanged: _recomputeEstimate,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    4,
                    22,
                    24,
                  ),
                  children: [
                    _label('Job title'),
                    _input(
                      _title,
                      hint: 'e.g. Event waiter',
                      validator: _required,
                    ),

                    const SizedBox(height: 18),

                    _label('Description'),
                    _input(
                      _description,
                      hint: 'Describe the role, schedule…',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 18),

                    // ==============================================
                    // BLOC 2 A AJOUTER - champ adresse + suggestions
                    // ==============================================
                    _label('Location'),
                    _input(
                      _address,
                      hint: 'Sion',
                      validator: _required,
                      onChanged: _onAddressChanged,
                    ),
                    if (_addressSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          children: [
                            for (final suggestion in _addressSuggestions)
                              ListTile(
                                dense: true,
                                title: Text(
                                  suggestion.label,
                                  style: TextStyle(
                                      fontSize: 14, color: colors.text),
                                ),
                                trailing: suggestion.canton.isEmpty
                                    ? null
                                    : Text(
                                        suggestion.canton,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: colors.accent,
                                        ),
                                      ),
                                onTap: () => _pickAddress(suggestion),
                              ),
                          ],
                        ),
                      ),
                    // ==================== FIN DU BLOC 2 ====================

                    const SizedBox(height: 18),

                    _column(
                      'Application deadline',
                      _input(
                        _endDateField,
                        hint: 'Sat 14 Jun',
                        readOnly: true,
                        onTap: _pickEndDate,
                        validator: _required,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Contract start date',
                      _input(
                        _contractStartDateField,
                        hint: 'Start date',
                        readOnly: true,
                        onTap: _pickContractStartDate,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Contract end date',
                      _input(
                        _contractEndDateField,
                        hint: 'Leave empty for permanent',
                        readOnly: true,
                        onTap: _pickContractEndDate,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Language',
                      _languagePicker(),
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Canton',
                      _dropdown(
                        value: _canton,
                        hint: 'Canton',
                        options: const [
                          'AG',
                          'AI',
                          'AR',
                          'BE',
                          'BL',
                          'BS',
                          'FR',
                          'GE',
                          'GL',
                          'GR',
                          'JU',
                          'LU',
                          'NE',
                          'NW',
                          'OW',
                          'SG',
                          'SH',
                          'SO',
                          'SZ',
                          'TG',
                          'TI',
                          'UR',
                          'VD',
                          'VS',
                          'ZG',
                          'ZH',
                        ],
                        onChanged: (v) =>
                            setState(() => _canton = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _column(
                            'Domain',
                            _dropdown(
                              value: _domains,
                              hint: 'Finance',
                              options: const [
                                'Education',
                                'Manufacturing',
                                'Healthcare',
                                'Finance',
                                'IT',
                                'Energy',
                                'Hospitality',
                                'Public Sector',
                                'Consulting',
                                'Pharma',
                                'Retail',
                                'Construction',
                              ],
                              onChanged: (v) =>
                                  setState(() => _domains = v),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _column(
                            'Degree',
                            _dropdown(
                              value: _degree,
                              hint: 'Bachelor',
                              options: const [
                                'PhD',
                                'Bachelor',
                                'Master',
                                'Apprenticeship',
                              ],
                              onChanged: (v) =>
                                  setState(() => _degree = v),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Role',
                      _dropdown(
                        value: _role,
                        hint: 'Junior',
                        options: const [
                          'Intern',
                          'Junior',
                          'Lead',
                          'Manager',
                          'Mid-level',
                          'Senior',
                        ],
                        onChanged: (v) =>
                            setState(() => _role = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Company size',
                      _dropdown(
                        value: _companySize,
                        hint: 'Startup (<50)',
                        options: const [
                          'Large (1000+)',
                          'Medium (200-1000)',
                          'Small (50-200)',
                          'Startup (<50)',
                        ],
                        onChanged: (v) =>
                            setState(() => _companySize = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _column(
                            'Min experience (years)',
                            _input(
                              _experienceMin,
                              hint: '0',
                              keyboard: TextInputType.number,
                              validator: _nonNegativeNumber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _column(
                            'Max experience (years)',
                            _input(
                              _experienceMax,
                              hint: '0',
                              keyboard: TextInputType.number,
                              validator: _nonNegativeNumber,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _column(
                      'Holidays (days/year)',
                      _input(
                        _holidays,
                        hint: '25',
                        keyboard: TextInputType.number,
                        validator: _nonNegativeNumber,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: _column(
                            'Salary (CHF/h)',
                            _input(
                              _salary,
                              hint: '22',
                              keyboard: TextInputType.number,
                              validator: _number,
                              
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _column(
                            'Work time (%)',
                            _input(
                              _workTime,
                              hint: '100%',
                              keyboard: TextInputType.number,
                              validator: _number,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _salaryEstimateBox(),

                    Text(
                      'PHOTOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: colors.muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _photoTile(),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish posting'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languagePicker() {
    final colors = Theme.of(context).extension<AppColors>()!;

    const options = [
      'French',
      'German',
      'English',
      'Italian',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((lang) {
        final selected = _languages.contains(lang);

        return FilterChip(
          label: Text(lang),
          selected: selected,
          showCheckmark: false,
          backgroundColor: colors.field,
          selectedColor: colors.softAccent,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? colors.accent : colors.muted,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? colors.accent : colors.border,
            ),
          ),
          onSelected: (isOn) {
            setState(() {
              if (isOn) {
                _languages.add(lang);
              } else {
                _languages.remove(lang);
              }
            });
            _recomputeEstimate();
          },
        );
      }).toList(),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> options,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      isExpanded: true,
      hint: Text(
        hint,
        style: TextStyle(
          fontSize: 15,
          color: colors.muted,
        ),
      ),
      style: TextStyle(
        fontSize: 15,
        color: colors.text,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: colors.muted,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.accent,
            width: 1.5,
          ),
        ),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o),
            ),
          )
          .toList(),
      onChanged: (v) {onChanged(v); _recomputeEstimate();},
    );
  }

  Widget _label(String t) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          color: colors.muted,
        ),
      ),
    );
  }

  Widget _column(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          field,
        ],
      );

  Widget _input(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: colors.text,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: colors.muted,
        ),
        filled: true,
        fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.accent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _salaryEstimateBox() {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: colors.softAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI salary estimate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _estimate == null
                      ? 'Fill in the fields above'
                      : '≈ ${_estimate!.toStringAsFixed(0)} CHF/year, '
                          '± a few thousand',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _estimateHourly == null
                ? '—'
                : '${_estimateHourly!.toStringAsFixed(2)} CHF/h',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoTile() {
    final colors = Theme.of(context).extension<AppColors>()!;

    return InkWell(
      onTap: _uploadingPhoto ? null : _pickPhoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: colors.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.border,
            width: 1.5,
          ),
          image: _pictureUrl != null
              ? DecorationImage(
                  image: NetworkImage(_pictureUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _uploadingPhoto
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : (_pictureUrl == null
                ? Icon(
                    Icons.add,
                    color: colors.muted,
                  )
                : null),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _number(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Required';
    }

    final n = double.tryParse(
      v.replaceAll(',', '.'),
    );

    return (n == null || n <= 0) ? 'Invalid' : null;
  }

  String? _nonNegativeNumber(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Required';
    }

    final n = double.tryParse(
      v.replaceAll(',', '.'),
    );

    return (n == null || n < 0) ? 'Invalid' : null;
  }
}