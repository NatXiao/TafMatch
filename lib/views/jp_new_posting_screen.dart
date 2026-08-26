import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';

// --- Design ---
const _accent = Color(0xFF4D73FF);
const _softAccent = Color(0xFFE6EDFF);
const _text = Color(0xFF1F212E);
const _muted = Color(0xFF8A91A3);
const _field = Color(0xFFF4F6FB);
const _border = Color(0xFFE6EBF5);

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
// Variables inside the memory
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

// Cleaning the memory when the user leaves the page
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

  // Opens a date picker and updates the end date field.
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

  // Validates the form and creates a new job posting in Firestore.
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
      endDate: _endDate,
      status: 'live',
    );

    // Create the job in Firestore and navigate back if successful.
    try {
      await context.read<JobProvider>().createJob(job);
      print('Job créé avec succès');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('ERREUR createJob: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not publish: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.chevron_left, size: 30, color: _text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Text('New posting',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _text)),
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
                    _column('End date',_input(_endDateField, hint: 'Sat 14 Jun',readOnly: true, onTap: _pickEndDate)),
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
                    const Text('PHOTOS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            letterSpacing: 0.5, color: _muted)),
                    const SizedBox(height: 12),
                    Row(children: [_photoTile(), const SizedBox(width: 12), _photoTile()]),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent, foregroundColor: Colors.white,
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
        backgroundColor: _field,
        selectedColor: _softAccent,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? _accent : _muted,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? _accent : _border),
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
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(fontSize: 15, color: _muted)),
      style: const TextStyle(fontSize: 15, color: _text),
      icon: const Icon(Icons.keyboard_arrow_down, color: _muted),
      decoration: InputDecoration(
        filled: true, fillColor: _field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 13, color: _muted)),
      );

  Widget _column(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_label(label), field],
      );

  Widget _input(TextEditingController c,
      {String? hint, int maxLines = 1, TextInputType? keyboard,
      bool readOnly = false, VoidCallback? onTap, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c, maxLines: maxLines, keyboardType: keyboard,
      readOnly: readOnly, onTap: onTap, validator: validator,
      style: const TextStyle(fontSize: 15, color: _text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, color: _muted),
        filled: true, fillColor: _field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }

  Widget _salaryEstimateBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: _softAccent, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI salary estimate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                SizedBox(height: 2),
                Text('Based on similar jobs', style: TextStyle(fontSize: 13, color: _muted)),
              ],
            ),
          ),
          // TODO: replace with the value from your salary prediction model.
          Text('—',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _accent)),
        ],
      ),
    );
  }

  Widget _photoTile() {
    return InkWell(
      onTap: () {
        // TODO: pick an image and upload it (Cloudinary), then keep the URL.
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connect the image picker to add photos.')));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          color: _field, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: const Icon(Icons.add, color: _muted),
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