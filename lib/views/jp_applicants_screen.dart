import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/views/chat_screen.dart';

typedef _Applicant = ({
  String name,
  String photoUrl,
  double rating,
  int reviews
});

class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({
    super.key,
    required this.job,
    this.userRepository,
    this.reviewRepository,
  });
  final Job job;
  final FirestoreUserRepository? userRepository;
  final FirestoreReviewRepository? reviewRepository;

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  late final FirestoreUserRepository _userRepository;
  late final FirestoreReviewRepository _reviewRepository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ApplicationProvider>()
          .listenToJobApplications(widget.job.id);
    });
    _userRepository = widget.userRepository ?? FirestoreUserRepository();
    _reviewRepository = widget.reviewRepository ?? FirestoreReviewRepository();
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

  void _openApplicantProfile(String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: studentId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

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
                    icon:
                        Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text('Applicants',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colors.text)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text(
                  'Tap an applicant to open their profile and rate them',
                  style: TextStyle(fontSize: 13, color: colors.muted)),
            ),
            Expanded(
              child: Consumer<ApplicationProvider>(
                builder: (context, provider, _) {
                  final apps = provider.applications;
                  if (apps.isEmpty) {
                    return Center(
                      child: Text('No applicants yet.',
                          style: TextStyle(fontSize: 15, color: colors.muted)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ApplicantCard(
                      application: apps[i],
                      job: widget.job,
                      loadApplicant: _loadApplicant,
                      onOpenProfile: () => _openApplicantProfile(apps[i].studentId),
                    )
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application, required this.job, required this.loadApplicant, required this.onOpenProfile});

  final Application application;
  final Job job;
  final Future<_Applicant> Function(String studentId) loadApplicant;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpenProfile,
            child: FutureBuilder<_Applicant>(
              future: loadApplicant(application.studentId),
              builder: (context, snap) {
                final a = snap.data ??
                    (name: 'Loading…', photoUrl: '', rating: 0.0, reviews: 0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.avatar,
                      backgroundImage: a.photoUrl.isNotEmpty
                          ? NetworkImage(a.photoUrl)
                          : null,
                      child: a.photoUrl.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 24)
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
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colors.accent)),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 18, color: colors.accent),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, size: 15, color: colors.accent),
                              const SizedBox(width: 4),
                              Text(
                                  '${a.rating.toStringAsFixed(1)} · ${a.reviews} reviews',
                                  style: TextStyle(
                                      fontSize: 13, color: colors.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(context, application.status),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                // TODO send a push notification to the student when their application is accepted or rejected
                child: ElevatedButton(
                  onPressed: application.status == 'accepted'
                      ? null
                      : () { _updateStatus(context, 'accepted');
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: application.status == 'rejected'
                      ? null
                      : () { _updateStatus(context, 'rejected');
                      },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.accent, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message'),
              style: TextButton.styleFrom(
                foregroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
              ),
              onPressed: () => _openChat(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final employerId = context.read<AuthProvider>().user?.uid ?? '';
    if (employerId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final conversation = await context.read<ChatProvider>().startConversation(
            employerId: employerId,
            studentId: application.studentId,
            jobId: job.id,
            jobTitle: job.title,
          );
      final user =
          await FirestoreUserRepository().getProfile(application.studentId);

      navigator.push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          otherUserId: application.studentId,
          otherUserName: user?.fullName ?? 'Applicant',
          otherUserPhotoUrl: user?.profilePictureUrl ?? '',
          jobTitle: conversation.jobTitle,
        ),
      ));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String status,
  ) async {
    try {
      // update the application
      await context
          .read<ApplicationProvider>()
          .updateStatus(application.id, status);

      // create the notification only if successful
      await context.read<NotificationProvider>().notify(
        userId: application.studentId,
        title: status == 'accepted'
            ? 'Application accepted'
            : 'Application rejected',
        message: status == 'accepted'
            ? 'Your application for "${job.title}" was accepted!'
            : 'Your application for "${job.title}" was rejected.',
        type: 'application_$status',
        jobId: job.id,
        applicationId: application.id,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update application: $e'),
          ),
        );
      }
    }
  }

  Widget _statusBadge(BuildContext context, String status) {
    final colors = Theme.of(context).extension<AppColors>()!;
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'accepted':
        label = 'Accepted';
        bg = colors.accent;
        fg = Colors.white;
      case 'rejected':
        label = 'Rejected';
        bg = colors.softDanger;
        fg = colors.danger;
      default:
        label = 'To review';
        bg = colors.softAccent;
        fg = colors.accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
