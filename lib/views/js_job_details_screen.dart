import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/models/transport_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/services/salary_estimator.dart';
import 'package:taf_match/utils/location_utils.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/utils/transports_api.dart';
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

  List<TransportModel> transports = [];
  bool isLoadingTransports = false;

  final _mapController = MapController();
  LatLng? _userPosition;
  LatLng? _jobPosition;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? FirestoreUserRepository();
    _reviewRepository = widget.reviewRepository ?? FirestoreReviewRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<ApplicationProvider>().listenToStudentApplications(uid);
    });
    retrieveTransports();
    updateMarkerOnMap();
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

  /// Salaire annuel estimé, en CHF.
  ///
  /// La valeur enregistrée à la publication fait foi. Les annonces créées
  /// avant l'intégration du modèle n'en ont pas : on la recalcule alors à la
  /// volée, ce qui est possible puisque les 13 colonnes sont dans le document.
  double? get _estimatedAnnual {
    final stored = widget.job.predictedSalaryChf;
    if (stored != null) return stored;
    try {
      return context.read<SalaryEstimator>().annualForJob(widget.job);
    } catch (_) {
      return null;
    }
  }

  /// La même estimation ramenée à l'heure, au taux d'activité de l'offre.
  double? get _estimatedHourly {
    final annual = _estimatedAnnual;
    if (annual == null) return null;
    return context
        .read<SalaryEstimator>()
        .hourlyFromAnnual(annual, widget.job.workloadPercent);
  }

  /// Écart entre le salaire proposé et l'estimation, en pourcentage.
  double? get _salaryGapPercent {
    final offered = widget.job.salaryChfPerHour;
    final estimate = _estimatedHourly;
    if (offered == null || estimate == null || estimate <= 0) return null;
    return (offered - estimate) / estimate * 100;
  }

  // Apply pour le job
  Future<void> _apply() async {
    setState(() => _applying = true);
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    try {
      await context.read<ApplicationProvider>().apply(
            Application(id: '', jobId: widget.job.id, studentId: uid),
          );
        if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your application has successfully been sent!', style: TextStyle(color: Colors.white)
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
    await context.read<NotificationProvider>().notify(
      userId: widget.job.employerId,
      title: 'New applicant',
      message: 'Someone applied to "${widget.job.title}"',
      type: 'application_received',
      jobId: widget.job.id,
    );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
          content: Text(
            'Could not apply: $e',
            style: TextStyle(color: Colors.white)
          ),
          backgroundColor: Colors.blue,
        ));
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
          content: Text(
            'Your application has been cancelled.',
            style: TextStyle(color: Colors.white)
          ),
          backgroundColor: Colors.blue,
        ));
        }
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
                  _salaryBox(colors),
                  const SizedBox(height: 24),

                  // --- Le détail de l'offre ---
                  _jobFacts(colors),

                  if (job.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Description',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.text)),
                    const SizedBox(height: 8),
                    Text(job.description,
                        style: TextStyle(fontSize: 14, height: 1.5, color: colors.text)),
                  ],

                  // Liste des transports disponibles
                  const SizedBox(height: 20),
                  Text('Routes · Next connections', style: TextStyle(fontSize: 18, color: colors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  Visibility(
                    visible: isLoadingTransports,
                    child: Text("Loading...", style: TextStyle(color: colors.muted)),
                  ),

                  Visibility(
                    visible: !isLoadingTransports && transports.isEmpty,
                    child: Text("No connections found.", style: TextStyle(color: colors.muted)),
                  ),  

                  Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: transports.length,
                            itemBuilder: (_, int index) {

                              return Container(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: colors.softAccent,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child:Text(transports[index].name, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    Text("${formatDate(transports[index].departure)} → ${formatDate(transports[index].arrival)} · ${transports[index].duration.inMinutes} min", style: TextStyle(color: colors.muted)),
                                  ],
                                ),
                              );

                            }
                          ),

                      ),
                    ]
                  ),


                  // Carte intéractive
                  const SizedBox(height: 20),
                  Text('Interactive map', style: TextStyle(fontSize: 18, color: colors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  Stack(
                    children: [

                      SizedBox(
                        height: 500,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(46.5, 6.6),
                            initialZoom: 8,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", // 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tafmatch.app',
                            ),
                            MarkerLayer(
                              markers: [
                                if (_userPosition != null)
                                  Marker(
                                    point: _userPosition!,
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.topCenter,
                                    child: const Icon(Icons.location_on, color: Colors.blue, size: 48),
                                  ),
                                if (_jobPosition != null)
                                  Marker(
                                    point: _jobPosition!,
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.topCenter,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 48),
                                  ),
                              ]
                            ),
                          ],
                        )
                      ),

                      if (_userPosition == null)
                        Container(
                          height: 500,
                          color: colors.field,
                          child: Center(child: CircularProgressIndicator(color: colors.accent)),
                        )
                    ],
                  )
                ],
              ),
            
            ),

          ],
        ),
      ),
    );
  }

  /// Salaire proposé à gauche, estimation du modèle à droite, écart en dessous.
  Widget _salaryBox(AppColors colors) {
    final job = widget.job;
    final hourly = _estimatedHourly;
    final gap = _salaryGapPercent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.softAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Text(
                    hourly != null ? '${hourly.toStringAsFixed(2)} CHF/h' : '—',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.accent),
                  ),
                ],
              ),
            ],
          ),

          // L'écart est l'information utile : le chiffre du modèle seul ne dit
          // rien de plus que ce que l'étudiant lit déjà à gauche.
          if (gap != null) ...[
            const SizedBox(height: 12),
            Text(
              gap.abs() < 1
                  ? 'The offer matches the estimate'
                  : 'The offer is ${gap.abs().toStringAsFixed(0)}% '
                      '${gap > 0 ? 'above' : 'below'} the estimate',
              style: TextStyle(fontSize: 13, color: colors.text),
            ),
          ],

          if (hourly != null) ...[
            const SizedBox(height: 4),
            Text(
              'Estimated from similar postings — typically off by a few '
              'thousand CHF a year. Not a benchmark.',
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }

  /// Les champs de l'offre qui alimentent le modèle, tels quels.
  Widget _jobFacts(AppColors colors) {
    final job = widget.job;

    final experience = job.experienceMax > job.experienceMin
        ? '${job.experienceMin.toStringAsFixed(0)}–'
            '${job.experienceMax.toStringAsFixed(0)} years'
        : '${job.experienceMin.toStringAsFixed(0)}+ years';

    final languages = [
      if (job.languagesEnglish > 0) 'English',
      if (job.languagesFrench > 0) 'French',
      if (job.languagesItalian > 0) 'Italian',
    ].join(', ');

    final facts = <String, String>{
      if (job.role.isNotEmpty) 'Role': job.role,
      if (job.diploma.isNotEmpty) 'Degree': job.diploma,
      if (job.industry.isNotEmpty) 'Industry': job.industry,
      if (job.canton.isNotEmpty) 'Canton': job.canton,
      if (job.companySize.isNotEmpty) 'Company size': job.companySize,
      'Experience': experience,
      'Workload': '${job.workloadPercent.toStringAsFixed(0)}%',
      'Holidays': '${job.holidays.toStringAsFixed(0)} days/year',
      'Contract': job.isPermanent ? 'Permanent' : 'Fixed term',
      if (languages.isNotEmpty) 'Languages': languages,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The offer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.text)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (final entry in facts.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(entry.key,
                            style: TextStyle(fontSize: 14, color: colors.muted)),
                      ),
                      Expanded(
                        child: Text(entry.value,
                            style: TextStyle(fontSize: 14, color: colors.text)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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

  void retrieveTransports() async {
    isLoadingTransports = true;

    final position = await LocationUtils.findDeviceLocation();
    final latitude = position.latitude;
    final longitude = position.longitude;

    String? location = await LocationUtils.getLocationName(latitude, longitude);

    if (location == null) {
      return;
    }

    final raw = await TransportsApi.findTransport(location, widget.job.address, DateTime.now());
    final data = jsonDecode(raw.body) as Map<String, dynamic>;

    transports.clear();
    if (data["connections"] != null) {
      data['connections'].forEach((v) {
        if (v["products"].length > 0) {
          transports.add(TransportModel.fromMap(v));
        }
      });
    }

    isLoadingTransports = false;
    setState(() {});
  }

  String formatDate(DateTime time) {
    return DateFormat.Hm().format(time);
  }


  void updateMarkerOnMap() async {

    final position = await LocationUtils.findDeviceLocation();
    final latitude = position.latitude;
    final longitude = position.longitude;

    final coord = await LocationUtils.getLocationCoord(widget.job.address);

    setState(() {
      _userPosition = LatLng(latitude, longitude);

      if (coord != null) {
        _jobPosition = LatLng(coord.$1, coord.$2);
      }
    });

    if (_userPosition == null && _jobPosition != null) {
      _mapController.move(_jobPosition!, 8);
    }
    else if (_userPosition != null && _jobPosition == null) {
      _mapController.move(_userPosition!, 8);
    }
    else {
      final bounds = LatLngBounds.fromPoints([_userPosition!, _jobPosition!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)));
    }
    
  }

}