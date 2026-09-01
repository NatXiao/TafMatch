import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/repositories/firestore_job_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/utils/theme.dart';

typedef _JobInfo = ({String title, String employer});

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, this.jobRepository, this.userRepository});
  final FirestoreJobRepository? jobRepository;
  final FirestoreUserRepository? userRepository;
  

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  // Récupération des repositoire uniquement (une fois)
  late final FirestoreJobRepository _jobRepository;
  late final FirestoreUserRepository _userRepository;
  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? FirestoreJobRepository();
    _userRepository = widget.userRepository ?? FirestoreUserRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<ApplicationProvider>().listenToStudentApplications(uid);
    });
  }

  // Récupération des jobs et employeurs pour chaque application (titre du job + nom de l'employeur)
  Future<_JobInfo> _loadJobInfo(String jobId) async {
    final job = await _jobRepository.getById(jobId);
    if (job == null) return (title: 'Unknown job', employer: '');
    final employer = await _userRepository.getProfile(job.employerId);
    return (title: job.title, employer: employer?.fullName ?? '');
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
              Text('My applications',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.text)),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<ApplicationProvider>(
                  builder: (context, provider, _) {
                    final apps = provider.applications;
                    if (apps.isEmpty) {
                      return Center(
                        child: Text('No applications yet.',
                            style: TextStyle(fontSize: 15, color: colors.muted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _ApplicationCard(
                        application: apps[i],
                        loadJobInfo: _loadJobInfo,
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

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.loadJobInfo});

  final Application application;
  final Future<_JobInfo> Function(String jobId) loadJobInfo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: const [BoxShadow(color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)],
      ),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<_JobInfo>(
              future: loadJobInfo(application.jobId),
              builder: (context, snap) {
                final info = snap.data ?? (title: 'Loading…', employer: '');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.text)),
                    const SizedBox(height: 4),
                    Text(info.employer,
                        style: TextStyle(fontSize: 14, color: colors.muted)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          _statusBadge(colors, application.status),
        ],
      ),
    );
  }

  Widget _statusBadge(AppColors colors, String status) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'accepted':
        label = 'Accepted'; bg = colors.accent; fg = Colors.white;
      case 'reviewed':
        label = 'Reviewed'; bg = colors.softAccent; fg = colors.accent;
      case 'rejected':
        label = 'Rejected'; bg = colors.field; fg = colors.muted;
      default:
        label = 'Submitted'; bg = colors.softAccent; fg = colors.accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}