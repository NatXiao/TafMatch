import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../repositories/firestore_application_repository.dart';
import '../models/job_model.dart';
import 'new_posting_screen.dart';

const _blue = Color(0xFF3D5AFE);

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});

  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  @override
  void initState() {
    super.initState();
    // On écoute les offres de l'employeur connecté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const uid = '8XdAkdYFmAUB584ZqJyFdMbcV0a2';
      if (uid != null) {
        context.read<JobProvider>().listenToEmployerJobs(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().jobs;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My postings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const CircleAvatar(radius: 14, backgroundColor: _blue),
                ],
              ),
              const SizedBox(height: 20),

              // Bouton New posting
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewPostingScreen()),
                  ),
                  child: const Text('+ New posting'),
                ),
              ),
              const SizedBox(height: 20),

              // Liste des offres
              Expanded(
                child: jobs.isEmpty
                    ? const Center(child: Text('Aucune offre pour le moment'))
                    : ListView.separated(
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => _JobCard(job: jobs[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: _blue,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline), label: 'Postings'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// Une carte d'offre
class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.read<JobProvider>().deleteJob(job.id),
                child: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne d'infos
          Text(
            '${job.address} · ${job.salaryChfPerHour ?? "?"} CHF/h',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Badge Live + nombre de candidats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.status,
                  style: const TextStyle(
                      color: _blue, fontWeight: FontWeight.w600),
                ),
              ),
              _ApplicantCount(jobId: job.id),
            ],
          ),
        ],
      ),
    );
  }
}

// Compte les candidats en temps réel pour une offre
class _ApplicantCount extends StatelessWidget {
  final String jobId;
  _ApplicantCount({required this.jobId});

  final _appRepo = FirestoreApplicationRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _appRepo.watchByJob(jobId),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Text(
          '$count applicant${count > 1 ? "s" : ""}',
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
        );
      },
    );
  }
}