import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/jp_applicants_screen.dart';
import 'package:taf_match/utils/theme.dart'; // pour AppColors

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

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  final _applicationRepository = FirestoreApplicationRepository();

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
    final colors = Theme.of(context).extension<AppColors>()!;

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
                  Text('My postings',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.text)),
                  const Spacer(),
                  // Bouton logout (en haut à droite)
                  InkWell(
                    onTap: () =>
                        Provider.of<AuthProvider>(context, listen: false).signOut(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: colors.softAccent, shape: BoxShape.circle),
                      child: Icon(Icons.logout, size: 18, color: colors.accent),
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
                    backgroundColor: colors.accent, foregroundColor: Colors.white,
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
                      return Center(
                        child: Text('No postings yet.',
                            style: TextStyle(fontSize: 15, color: colors.muted)),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: colors.border)),
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
              onTap: () {}, // on est déjà dessus, rien à faire
            ),
            _NavItem(
              label: 'Profile',
              active: false,
              // TODO: remplacer AboutScreen par ta vraie page profil
              onTap: () => Navigator.push(context,
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = active ? colors.accent : colors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                color: active ? colors.accent : colors.border, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
          border: Border.all(color: colors.border),
          boxShadow: const [BoxShadow(color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                ),
                OutlinedButton(
                  onPressed: () => _confirmDelete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.muted,
                    side: BorderSide(color: colors.muted, width: 1.4),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(parts.join(' · '), style: TextStyle(fontSize: 13, color: colors.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (job.status == 'live')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: colors.softAccent, borderRadius: BorderRadius.circular(999)),
                    child: Text('Live',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accent)),
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