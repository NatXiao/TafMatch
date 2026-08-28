import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/job_provider.dart';

import '../fakes.dart';

Job _job(String id, {String employerId = 'emp1', String status = 'live'}) =>
    Job(id: id, employerId: employerId, title: 'Job $id', status: status);

void main() {
  late FakeJobRepository repository;
  late JobProvider provider;

  setUp(() {
    repository = FakeJobRepository();
    provider = JobProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    repository.dispose();
  });

  // The provider exposes an empty list before any stream emits.
  test('starts with an empty list', () {
    expect(provider.jobs, isEmpty);
  });

  // Listening to live jobs fills the list and notifies listeners.
  test('listenToLiveJobs updates the list and notifies', () async {
    final jobs = [_job('j1'), _job('j2')];

    var notified = false;
    provider.addListener(() => notified = true);

    provider.listenToLiveJobs();
    repository.emit(jobs);
    await Future<void>.delayed(Duration.zero);

    expect(provider.jobs, jobs);
    expect(notified, isTrue);
  });

  // Listening to an employer's jobs updates the list when the stream emits.
  test('listenToEmployerJobs updates the list when the stream emits', () async {
    final jobs = [_job('j1', employerId: 'emp9')];

    provider.listenToEmployerJobs('emp9');
    repository.emit(jobs);
    await Future<void>.delayed(Duration.zero);

    expect(provider.jobs, jobs);
  });

  // Starting a new listen cancels the previous subscription without errors.
  test('a new listen cancels the previous subscription', () async {
    provider.listenToLiveJobs();
    provider.listenToEmployerJobs('emp1');

    repository.emit([_job('j1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.jobs, hasLength(1));
  });

  // createJob forwards the job to the repository and returns the generated id.
  test('createJob delegates to the repository and returns the new id', () async {
    repository.createIdToReturn = 'job-42';
    final job = _job('');

    final id = await provider.createJob(job);

    expect(repository.createCallCount, 1);
    expect(repository.lastCreatedJob, same(job));
    expect(id, 'job-42');
  });

  // updateJob forwards both the id and the changed fields to the repository.
  test('updateJob delegates to the repository with id and fields', () async {
    await provider.updateJob('job-1', {'title': 'New title'});

    expect(repository.lastUpdatedId, 'job-1');
    expect(repository.lastUpdatedFields, {'title': 'New title'});
  });

  // deleteJob forwards the given id to the repository.
  test('deleteJob delegates to the repository with the right id', () async {
    await provider.deleteJob('job-1');

    expect(repository.lastDeletedId, 'job-1');
  });
}