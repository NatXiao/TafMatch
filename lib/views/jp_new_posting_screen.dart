import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class NewPostingScreen extends StatefulWidget {
  const NewPostingScreen({super.key});
  @override
  State<NewPostingScreen> createState() => NewPostingScreenState();
}

class NewPostingScreenState extends State<NewPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _salary = TextEditingController();
  final _workTime = TextEditingController();
  final _endDateField = TextEditingController();
  final List<String> _languages = [];
  DateTime? _endDate;
  String? _degree;
  String? _domains;
  bool _saving = false;
  final _picker = ImagePicker();
  String? _pictureUrl;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _salary.dispose();
    _workTime.dispose();
    _endDateField.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context, initialDate: _endDate ?? now,
      firstDate: now, lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateField.text = _shortDate(picked);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final imageRepository = context.read<ImageStorageRepository>();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final url = await imageRepository.uploadImage(bytes, picked.name);
      if (!mounted) return;
      setState(() => _pictureUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed. Please try again.')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final employerId = context.read<AuthProvider>().user?.uid ?? '';
    final job = Job(
      id: '',
      employerId: employerId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      address: _address.text.trim(),
      domainName: _domains?.trim() ?? '',
      degree: _degree?.trim() ?? '',
      languages: _languages.join(', '),
      salaryChfPerHour: double.tryParse(_salary.text.replaceAll(',', '.')),
      workPercentage: int.tryParse(_workTime.text.replaceAll(RegExp(r'[^0-9]'), '')),
      pictureUrl: _pictureUrl ?? '',
      endDate: _endDate,
      status: 'live',
    );

    try {
      await context.read<JobProvider>().createJob(job);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not publish: $e')));
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
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text('New posting',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.text)),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  children: [
                    _label('Job title'),
                    _input(_title, hint: 'e.g. Event waiter', validator: _required),
                    const SizedBox(height: 18),
                    _label('Description'),
                    _input(_description, hint: 'Describe the role, schedule…', maxLines: 4),
                    const SizedBox(height: 18),
                    _label('Location'),
                    _input(_address, hint: 'Sion', validator: _required),
                    const SizedBox(height: 18),
                    _column('Application deadline', _input(_endDateField, hint: 'Sat 14 Jun', readOnly: true, onTap: _pickEndDate)),
                    const SizedBox(height: 18),
                    _column('Language', _languagePicker()),
                    Row(children: [
                      Expanded(child: _column('Domain',
                        _dropdown(
                          value: _domains,
                          hint: 'Finance',
                          options: const ['Education', 'Manufacturing', 'Healthcare', 'Finance', 'IT', 'Energy', 'Hospitality', 'Public Sector', 'Consulting', 'Pharma', 'Retail', 'Construction'],
                          onChanged: (v) => setState(() => _domains = v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ))),
                      const SizedBox(width: 14),
                      Expanded(child: _column('Degree',
                        _dropdown(
                          value: _degree,
                          hint: 'Bachelor',
                          options: const ['PhD', 'Bachelor', 'Master', 'Apprenticeship'],
                          onChanged: (v) => setState(() => _degree = v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ))),
                    ]),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(child: _column('Salary (CHF/h)',
                          _input(_salary, hint: '22',
                              keyboard: TextInputType.number, validator: _number))),
                      const SizedBox(width: 14),
                      Expanded(child: _column('Work time (%)',
                          _input(_workTime, hint: '40%', keyboard: TextInputType.number, validator: _number))),
                    ]),
                    const SizedBox(height: 18),
                    _salaryEstimateBox(),
                    Text('PHOTOS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            letterSpacing: 0.5, color: colors.muted)),
                    const SizedBox(height: 12),
                    _photoTile(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent, foregroundColor: Colors.white,
                          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
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
    const options = ['French', 'German', 'English', 'Italian'];
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
            side: BorderSide(color: selected ? colors.accent : colors.border),
          ),
          onSelected: (isOn) {
            setState(() {
              if (isOn) {
                _languages.add(lang);
              } else {
                _languages.remove(lang);
              }
            });
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
      value: value,
      validator: validator,
      isExpanded: true,
      hint: Text(hint, style: TextStyle(fontSize: 15, color: colors.muted)),
      style: TextStyle(fontSize: 15, color: colors.text),
      icon: Icon(Icons.keyboard_arrow_down, color: colors.muted),
      decoration: InputDecoration(
        filled: true, fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.accent, width: 1.5)),
      ),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _label(String t) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: TextStyle(fontSize: 13, color: colors.muted)),
    );
  }

  Widget _column(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_label(label), field],
      );

  Widget _input(TextEditingController c,
      {String? hint, int maxLines = 1, TextInputType? keyboard,
      bool readOnly = false, VoidCallback? onTap, String? Function(String?)? validator}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextFormField(
      controller: c, maxLines: maxLines, keyboardType: keyboard,
      readOnly: readOnly, onTap: onTap, validator: validator,
      style: TextStyle(fontSize: 15, color: colors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: colors.muted),
        filled: true, fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.accent, width: 1.5)),
      ),
    );
  }

  Widget _salaryEstimateBox() {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: colors.softAccent, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI salary estimate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                const SizedBox(height: 2),
                Text('Based on similar jobs', style: TextStyle(fontSize: 13, color: colors.muted)),
              ],
            ),
          ),
          // TODO: remplacer en utilisant le vrai estimateur de salaire
          Text('—',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.accent)),
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
      width: 76, height: 76,
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1.5),
        image: _pictureUrl != null
            ? DecorationImage(image: NetworkImage(_pictureUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: _uploadingPhoto
          ? const Center(
              child: SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : (_pictureUrl == null ? Icon(Icons.add, color: colors.muted) : null),
    ),
  );
}

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _number(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.replaceAll(',', '.'));
    return (n == null || n <= 0) ? 'Invalid' : null;
  }
}