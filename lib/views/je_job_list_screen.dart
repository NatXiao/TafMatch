import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/views/je_job_details_screen.dart';
import 'package:taf_match/utils/theme.dart';

String _shortDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _searchController = TextEditingController();

  // --- État des filtres ---
  RangeValues _salaryRange = const RangeValues(0, 250);
  RangeValues _percentRange = const RangeValues(0, 100);
  final Set<String> _selectedCategories = {};

  static const _categories = [
    'Education', 'Manufacturing', 'Healthcare', 'Finance', 'IT', 'Energy',
    'Hospitality', 'Public Sector', 'Consulting', 'Pharma', 'Retail', 'Construction',
  ];

  // Compte combien de filtres sont actifs (pour l'afficher sur le bouton)
  int get _activeFilterCount {
    var n = 0;
    if (_salaryRange.start > 0 || _salaryRange.end < 250) n++;
    if (_percentRange.start > 0 || _percentRange.end < 100) n++;
    if (_selectedCategories.isNotEmpty) n++;
    return n;
  }

  @override
  // Listen to live jobs when the screen is initialized.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().listenToLiveJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // --- Titre + logout ---
              Row(
                children: [
                  Text('Jobs',
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
              // --- Recherche ---
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 15, color: colors.text),
                decoration: InputDecoration(
                  hintText: 'Search a job…',
                  hintStyle: TextStyle(fontSize: 15, color: colors.muted),
                  prefixIcon: Icon(Icons.circle, size: 10, color: colors.muted),
                  filled: true,
                  fillColor: colors.field,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.accent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              // --- Bouton Filters ---
              Row(
                children: [
                  InkWell(
                    onTap: _openFilters,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0 ? colors.softAccent : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _activeFilterCount > 0 ? colors.accent : colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune, size: 16,
                              color: _activeFilterCount > 0 ? colors.accent : colors.text),
                          const SizedBox(width: 8),
                          Text(
                            _activeFilterCount > 0 ? 'Filters ($_activeFilterCount)' : 'Filters',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _activeFilterCount > 0 ? colors.accent : colors.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Bouton pour tout effacer (visible seulement si des filtres sont actifs)
                  if (_activeFilterCount > 0)
                    InkWell(
                      onTap: () => setState(() {
                        _salaryRange = const RangeValues(0, 250);
                        _percentRange = const RangeValues(0, 100);
                        _selectedCategories.clear();
                      }),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text('Clear',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: colors.muted)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // --- Liste ---
              Expanded(
                child: Consumer<JobProvider>(
                  builder: (context, jobProvider, _) {
                    // Filtrage des jobs : recherche + salaire + pourcentage + catégorie
                    final jobs = jobProvider.jobs.where((job) {
                      final matchesQuery = query.isEmpty ||
                          job.title.toLowerCase().contains(query) ||
                          job.address.toLowerCase().contains(query);

                      final salary = job.salaryChfPerHour;
                      final matchesSalary = salary == null ||
                          (salary >= _salaryRange.start && salary <= _salaryRange.end);

                      final percent = job.workPercentage;
                      final matchesPercent = percent == null ||
                          (percent >= _percentRange.start && percent <= _percentRange.end);

                      final matchesCategory = _selectedCategories.isEmpty ||
                          _selectedCategories.contains(job.domainName);

                      return matchesQuery && matchesSalary && matchesPercent && matchesCategory;
                    }).toList();

                    if (jobs.isEmpty) {
                      return Center(
                        child: Text('No jobs found.',
                            style: TextStyle(fontSize: 15, color: colors.muted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _JobCard(job: jobs[i]),
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

  // --- Panneau des filtres ---
  void _openFilters() {
    // Copies temporaires : on ne modifie l'écran que si l'utilisateur valide.
    var salary = _salaryRange;
    var percent = _percentRange;
    final cats = {..._selectedCategories};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<AppColors>()!;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + Reset
                    Row(
                      children: [
                        Text('Filters',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            salary = const RangeValues(0, 250);
                            percent = const RangeValues(0, 100);
                            cats.clear();
                          }),
                          child: Text('Reset', style: TextStyle(color: colors.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Salaire
                    Text('Salary (CHF/h): ${salary.start.round()} – ${salary.end.round()}',
                        style: TextStyle(fontSize: 14, color: colors.text)),
                    RangeSlider(
                      values: salary,
                      min: 0, max: 250, divisions: 250,
                      activeColor: colors.accent,
                      labels: RangeLabels('${salary.start.round()}', '${salary.end.round()}'),
                      onChanged: (v) => setSheetState(() => salary = v),
                    ),
                    const SizedBox(height: 8),

                    // Pourcentage
                    Text('Work percentage: ${percent.start.round()}% – ${percent.end.round()}%',
                        style: TextStyle(fontSize: 14, color: colors.text)),
                    RangeSlider(
                      values: percent,
                      min: 0, max: 100, divisions: 100,
                      activeColor: colors.accent,
                      labels: RangeLabels('${percent.start.round()}%', '${percent.end.round()}%'),
                      onChanged: (v) => setSheetState(() => percent = v),
                    ),
                    const SizedBox(height: 16),

                    // Catégories
                    Text('Categories', style: TextStyle(fontSize: 14, color: colors.text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _categories.map((c) {
                        final selected = cats.contains(c);
                        return FilterChip(
                          label: Text(c),
                          selected: selected,
                          showCheckmark: false,
                          backgroundColor: colors.field,
                          selectedColor: colors.softAccent,
                          labelStyle: TextStyle(
                            color: selected ? colors.accent : colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(color: selected ? colors.accent : colors.border),
                          onSelected: (_) => setSheetState(() {
                            if (selected) {
                              cats.remove(c);
                            } else {
                              cats.add(c);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Appliquer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _salaryRange = salary;
                            _percentRange = percent;
                            _selectedCategories
                              ..clear()
                              ..addAll(cats);
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent, foregroundColor: Colors.white,
                          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Job details card
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final subtitle = [
      if (job.address.isNotEmpty) job.address,
      if (job.endDate != null) _shortDate(job.endDate!),
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
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
            Text(job.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 14, color: colors.muted)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Vignette image (placeholder si pas de photo)
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: colors.field,
                    borderRadius: BorderRadius.circular(14),
                    image: job.pictureUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(job.pictureUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: job.pictureUrl.isEmpty
                      ? Center(
                          child: Container(width: 12, height: 12,
                              decoration: BoxDecoration(color: colors.avatar, shape: BoxShape.circle)))
                      : null,
                ),
                const SizedBox(width: 16),
                if (job.salaryChfPerHour != null)
                  Text('${job.salaryChfPerHour!.toStringAsFixed(0)} CHF/h',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.accent)),
                const Spacer(),
                if (job.salaryChfPerHour != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: colors.softAccent, borderRadius: BorderRadius.circular(999)),
                    child: Text('≈ est. ${job.salaryChfPerHour!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accent)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}