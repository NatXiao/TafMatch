import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';

const _blue = Color(0xFF3D5AFE);

class NewPostingScreen extends StatefulWidget {
  const NewPostingScreen({super.key});

  @override
  State<NewPostingScreen> createState() => _NewPostingScreenState();
}

class _NewPostingScreenState extends State<NewPostingScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController(text: 'Sion');
  final _salary = TextEditingController();
  final _workTime = TextEditingController();
  final _degree = TextEditingController();
  final _domain = TextEditingController();
  final _language = TextEditingController();
  DateTime? _endDate;

  bool _isSaving = false;

  Future<void> _publish() async {
    const uid = '8XdAkdYFmAUB584ZqJyFdMbcV0a2';

    setState(() => _isSaving = true);

    final job = Job(
      id: '',
      employerId: uid,
      title: _title.text,
      description: _description.text,
      address: _location.text,
      degree: _degree.text,
      domainName: _domain.text,
      languages: _language.text,
      salaryChfPerHour: double.tryParse(_salary.text),
      endDate: _endDate,
      status: 'live',
    );

    await context.read<JobProvider>().createJob(job);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('New posting',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Job title', _title, hint: 'e.g. Event waiter'),
          _field('Description', _description,
              hint: 'Describe the role, schedule…', lines: 3),
          _field('Location', _location),

          // Salaire + temps de travail côte à côte
          Row(
            children: [
              Expanded(
                  child: _field('Salary (CHF/h)', _salary,
                      hint: '22', number: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field('Work time (%)', _workTime,
                      hint: '40%', number: true)),
            ],
          ),

          // Estimation IA (placeholder — voir note)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(                        // ← ajouté
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AI salary estimate',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Based on similar jobs',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),                               // ← ajouté
                const SizedBox(width: 8),        // petit espace de sécurité
                const Text('— CHF/h',
                    style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date de fin + diplôme
          Row(
            children: [
              Expanded(child: _dateField(context)),
              const SizedBox(width: 12),
              Expanded(child: _field('Degree', _degree, hint: 'Bachelor')),
            ],
          ),
          // Domaine + langue
          Row(
            children: [
              Expanded(
                  child: _field('Domain', _domain, hint: 'Hospitality')),
              const SizedBox(width: 12),
              Expanded(
                  child: _field('Language', _language, hint: 'French')),
            ],
          ),

          const SizedBox(height: 12),
          const Text('PHOTOS',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          // Placeholders photos (voir note)
          Row(children: [_photoBox(), const SizedBox(width: 12), _photoBox()]),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _publish,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish posting'),
            ),
          ),
        ],
      ),
    );
  }

  // Un champ de texte réutilisable
  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int lines = 1, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: lines,
            keyboardType: number ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF4F6FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('End date',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                initialDate: DateTime.now(),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _endDate == null
                    ? 'Choisir'
                    : '${_endDate!.day}/${_endDate!.month}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.add, color: Colors.grey),
    );
  }
}