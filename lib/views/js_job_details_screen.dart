import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

// Information a affiché de l'employeur
typedef _Employer = ({String name, String photoUrl, double rating, int reviews});

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    this.userRepository,
    this.reviewRepository,
  });


  final Job job;

  final FirestoreUserRepository? userRepository;
  final FirestoreReviewRepository? reviewRepository;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final FirestoreUserRepository _userRepository;
  late final FirestoreReviewRepository _reviewRepository;
  bool _applying = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? FirestoreUserRepository();
    _reviewRepository = widget.reviewRepository ?? FirestoreReviewRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<ApplicationProvider>().listenToStudentApplications(uid);
    });
  }

  // Charge les infos de l'employeur (nom, photo, note, nb reviews)
  Future<_Employer> _loadEmployer() async {
    final user = await _userRepository.getProfile(widget.job.employerId);
    final reviews = await _reviewRepository.watchForUser(widget.job.employerId).first;
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

  // Ouvre le profil de l'employeur. 
  void _openEmployerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.job.employerId)),
    );
  }

  // Apply pour le job
  Future<void> _apply() async {
    setState(() => _applying = true);
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    try {
      await context.read<ApplicationProvider>().apply(
            Application(id: '', jobId: widget.job.id, studentId: uid),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not apply: $e')));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  // Annule (retire) la candidature après confirmation.
  Future<void> _cancel(Application app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel application?'),
        content: const Text('This will withdraw your application for this job.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await context.read<ApplicationProvider>().cancel(app.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not cancel: $e')));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final job = widget.job;

    // Cherche si l'étudiant a déjà postulé pour ce job
    final apps = context.watch<ApplicationProvider>().applications;
    Application? myApp;
    for (final a in apps) {
      if (a.jobId == job.id) { myApp = a; break; }
    }

  // --- Sous-titre (adresse + date) ---
    final subtitle = [
      if (job.address.isNotEmpty) job.address,
      if (job.endDate != null) _shortDate(job.endDate!),
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Barre du haut ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text('Job details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  // --- Image (tap = profil employeur) ---
                  Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: colors.field,
                        borderRadius: BorderRadius.circular(18),
                        image: job.pictureUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(job.pictureUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: job.pictureUrl.isEmpty
                          ? Center(
                              child: Container(width: 16, height: 16,
                                  decoration: BoxDecoration(color: colors.avatar, shape: BoxShape.circle)))
                          : null,
                    ),
                  const SizedBox(height: 18),

                  // --- Titre + sous-titre ---
                  Text(job.title,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 15, color: colors.muted)),
                  const SizedBox(height: 16),

                  // --- Carte employeur (tap = profil / notation) ---
                  FutureBuilder<_Employer>(
                    future: _loadEmployer(),
                    builder: (context, snap) {
                      final e = snap.data ??
                          (name: 'Loading…', photoUrl: '', rating: 0.0, reviews: 0);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _openEmployerProfile,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.accent, width: 1.4),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: colors.avatar,
                                backgroundImage: e.photoUrl.isNotEmpty ? NetworkImage(e.photoUrl) : null,
                                child: e.photoUrl.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.name,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 15, color: colors.accent),
                                        const SizedBox(width: 4),
                                        Text('${e.rating.toStringAsFixed(1)} · ${e.reviews} reviews',
                                            style: TextStyle(fontSize: 13, color: colors.muted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('View profile',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accent)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // --- Petit texte d'aide sous la carte ---
                  Text('Tap the job or employer to open their profile or rate them',
                      style: TextStyle(fontSize: 12, color: colors.muted)),
                  const SizedBox(height: 24),

                  // --- Ta candidature ---
                  Row(
                    children: [
                      Text('Your application',
                          style: TextStyle(fontSize: 15, color: colors.muted)),
                      const Spacer(),
                      if (myApp != null) ...[
                        _statusBadge(colors, myApp.status),
                        // Bouton d'annulation (sauf si déjà refusée)
                        if (myApp.status != 'rejected') ...[
                          const SizedBox(width: 8),
                          _cancelButton(colors, myApp),
                        ],
                      ] else
                        _applyButton(colors),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Salaire + estimation ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.softAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offered salary', style: TextStyle(fontSize: 13, color: colors.muted)),
                            const SizedBox(height: 4),
                            Text(
                              job.salaryChfPerHour != null
                                  ? '${job.salaryChfPerHour!.toStringAsFixed(0)} CHF/h'
                                  : '—',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.text),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('AI estimate', style: TextStyle(fontSize: 13, color: colors.muted)),
                            const SizedBox(height: 4),
                            // TODO: brancher la valeur du modèle de prediciton
                            Text('—',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyButton(AppColors colors) {
    return ElevatedButton(
      onPressed: _applying ? null : _apply,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent, foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: _applying
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Apply'),
    );
  }

  Widget _cancelButton(AppColors colors, Application app) {
    return OutlinedButton(
      onPressed: _cancelling ? null : () => _cancel(app),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.muted,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: _cancelling
          ? const SizedBox(height: 14, width: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Cancel'),
    );
  }

  Widget _statusBadge(AppColors colors, String status) {
    late final String label;
    switch (status) {
      case 'accepted': label = 'Accepted';
      case 'rejected': label = 'Rejected';
      case 'reviewed': label = 'Reviewed';
      default: label = 'Submitted';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.softAccent, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accent)),
    );
  }
}