import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/jp_applicants_screen.dart';

// --- Design  ---
const _accent = Color(0xFF4D73FF);
const _softAccent = Color(0xFFE6EDFF);
const _text = Color(0xFF1F212E);
const _muted = Color(0xFF8A91A3);
const _border = Color(0xFFE6EBF5);

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});
  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

// Variables inside the memory
class _MyPostingsScreenState extends State<MyPostingsScreen> {
  final _applicationRepository = FirestoreApplicationRepository();

  // Listen to the job postings of the current employer.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<JobProvider>().listenToEmployerJobs(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('My postings',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _text)),
                  const Spacer(),
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: _softAccent, shape: BoxShape.circle),
                    child: Center(
                      child: Container(width: 14, height: 14,
                          decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewPostingScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('New posting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent, foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<JobProvider>(
                  builder: (context, jobProvider, _) {
                    final jobs = jobProvider.jobs;
                    if (jobs.isEmpty) {
                      return const Center(
                        child: Text('No postings yet.',
                            style: TextStyle(fontSize: 15, color: _muted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _JobCard(
                        job: jobs[i],
                        applicationRepository: _applicationRepository,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
            _NavItem(
              label: 'Postings',
              active: true,
              onTap: () {},   // on est déjà dessus, rien à faire
            ),
            _NavItem(
              label: 'Profile',
              active: false,
              onTap: () => Navigator.push(context,
              // TODO A CHANGER ABOUTSCREEN AVEC PAGE PROFILE
                  MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _accent : _muted;
    return InkWell(                   
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: active ? _accent : _border, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.applicationRepository});
  final Job job;
  final FirestoreApplicationRepository applicationRepository;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (job.address.isNotEmpty) job.address,
      if (job.endDate != null) _shortDate(job.endDate!),
      if (job.salaryChfPerHour != null) '${job.salaryChfPerHour!.toStringAsFixed(0)} CHF/h',
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ApplicantsScreen(job: job)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: const [BoxShadow(color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                ),
                OutlinedButton(
                  onPressed: () => _confirmDelete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: _muted, width: 1.4),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(parts.join(' · '), style: const TextStyle(fontSize: 13, color: _muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (job.status == 'live')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: _softAccent, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Live',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _accent)),
                  ),
                const Spacer(),
                // One-shot count of applicants for this posting.

              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete posting?'),
        content: Text('"${job.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE5484D))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<JobProvider>().deleteJob(job.id);
    }
  }
}