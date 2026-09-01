import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/services/salary_estimator.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';
import 'package:taf_match/views/jp_applicants_screen.dart';
import 'package:taf_match/utils/theme.dart';

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key, this.applicationRepository});
  final FirestoreApplicationRepository? applicationRepository;
  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  late final FirestoreApplicationRepository _applicationRepository;
  @override
  void initState() {
    super.initState();
    _applicationRepository = widget.applicationRepository ?? FirestoreApplicationRepository();

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

    final estimate = _estimateLine(context);

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

            // Postings created before the model was integrated have no
            // prediction stored, so this line simply does not appear.
            if (estimate != null) ...[
              const SizedBox(height: 6),
              Text(estimate,
                  style: TextStyle(fontSize: 13, color: colors.accent)),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: job.isLive ? colors.softAccent : colors.field,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    job.isLive ? 'Live' : 'Closed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: job.isLive ? colors.accent : colors.muted,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "AI estimate 47.50 CHF/h · offer 8% below" — or null when the posting
  /// carries no prediction.
  ///
  /// The stored value is a yearly salary, because that is what the model
  /// predicts; the hourly figure is derived here with the app's own
  /// convention, so old postings stay correct if that convention changes.
  String? _estimateLine(BuildContext context) {
    final predicted = job.predictedSalaryChf;
    if (predicted == null) return null;

    final hourly = context
        .read<SalaryEstimator>()
        .hourlyFromAnnual(predicted, job.workloadPercent);

    final buffer = StringBuffer('AI estimate ${hourly.toStringAsFixed(2)} CHF/h');

    final actual = job.salaryChfPerHour;
    if (actual != null && hourly > 0) {
      final gap = (actual - hourly) / hourly * 100;
      if (gap.abs() >= 1) {
        buffer.write(' · offer ${gap.abs().toStringAsFixed(0)}% '
            '${gap > 0 ? 'above' : 'below'}');
      } else {
        buffer.write(' · offer matches');
      }
    }

    return buffer.toString();
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