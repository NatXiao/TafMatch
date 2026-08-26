import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';

// --- Design ---
const _accent = Color(0xFF4D73FF);
const _softAccent = Color(0xFFE6EDFF);
const _text = Color(0xFF1F212E);
const _muted = Color(0xFF8A91A3);
const _border = Color(0xFFE6EBF5);
const _avatar = Color(0xFFCCD9F0);
const _danger = Color(0xFFE5484D);
const _softDanger = Color(0xFFFDEBEC);


typedef _Applicant = ({String name, String photoUrl, double rating, int reviews});

class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({super.key, required this.job});
  final Job job;

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final _userRepository = FirestoreUserRepository();
  final _reviewRepository = FirestoreReviewRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().listenToJobApplications(widget.job.id);
    });
  }

  Future<_Applicant> _loadApplicant(String studentId) async {
    final user = await _userRepository.getProfile(studentId);
    final reviews = await _reviewRepository.watchForUser(studentId).first;
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    return (
      name: user?.fullName ?? 'Unknown',
      photoUrl: user?.profilePictureUrl ?? '',
      rating: avg,
      reviews: reviews.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30, color: _text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Text('Applicants',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _text)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Tap an applicant to open their profile and rate them',
                  style: TextStyle(fontSize: 13, color: _muted)),
            ),
            Expanded(
              child: Consumer<ApplicationProvider>(
                builder: (context, provider, _) {
                  final apps = provider.applications;
                  if (apps.isEmpty) {
                    return const Center(
                      child: Text('No applicants yet.',
                          style: TextStyle(fontSize: 15, color: _muted)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ApplicantCard(
                      application: apps[i],
                      loadApplicant: _loadApplicant,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application, required this.loadApplicant});

  final Application application;
  final Future<_Applicant> Function(String studentId) loadApplicant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [BoxShadow(color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)],
      ),
      child: Column(
        children: [
          FutureBuilder<_Applicant>(
            future: loadApplicant(application.studentId),
            builder: (context, snap) {
              final a = snap.data ??
                  (name: 'Loading…', photoUrl: '', rating: 0.0, reviews: 0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _avatar,
                    backgroundImage:
                        a.photoUrl.isNotEmpty ? NetworkImage(a.photoUrl) : null,
                    child: a.photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(a.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w600, color: _accent)),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: _accent),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 15, color: _accent),
                            const SizedBox(width: 4),
                            Text('${a.rating.toStringAsFixed(1)} · ${a.reviews} reviews',
                                style: const TextStyle(fontSize: 13, color: _muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(application.status),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: application.status == 'accepted'
                      ? null
                      : () => context.read<ApplicationProvider>()
                          .updateStatus(application.id, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent, foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: application.status == 'rejected'
                      ? null
                      : () => context.read<ApplicationProvider>()
                          .updateStatus(application.id, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'accepted':
        label = 'Accepted'; bg = _accent; fg = Colors.white;
      case 'rejected':
        label = 'Rejected'; bg = _softDanger; fg = _danger;
      default:
        label = 'To review'; bg = _softAccent; fg = _accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}