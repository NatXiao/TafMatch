import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/providers/application_provider.dart';

import '../fakes.dart';

Application _app(String id, {String jobId = 'job1', String studentId = 'stu1'}) =>
    Application(id: id, jobId: jobId, studentId: studentId);

void main() {
  late FakeApplicationRepository repository;
  late ApplicationProvider provider;

  setUp(() {
    repository = FakeApplicationRepository();
    provider = ApplicationProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    repository.dispose();
  });

  // The provider exposes an empty list before any stream emits.
  test('starts with an empty list', () {
    expect(provider.applications, isEmpty);
  });

  // apply() forwards the given application to the repository once.
  test('apply delegates to the repository with the right application', () async {
    final app = _app('', jobId: 'job1', studentId: 'stu1');

    await provider.apply(app);

    expect(repository.applyCallCount, 1);
    expect(repository.lastAppliedApplication, same(app));
  });

  // cancel() forwards the given application id to the repository once.
  test('cancel delegates to the repository with the right id', () async {
    await provider.cancel('app123');

    expect(repository.cancelCallCount, 1);
    expect(repository.lastCancelledId, 'app123');
  });

  // updateStatus() forwards both the id and the new status to the repository.
  test('updateStatus delegates to the repository with id and status', () async {
    await provider.updateStatus('app123', 'accepted');

    expect(repository.lastStatusId, 'app123');
    expect(repository.lastStatus, 'accepted');
  });

  // Listening to a student's applications fills the list and notifies listeners.
  test('listenToStudentApplications updates the list and notifies', () async {
    final apps = [_app('a1'), _app('a2')];

    var notified = false;
    provider.addListener(() => notified = true);

    provider.listenToStudentApplications('stu1');
    repository.emit(apps);
    await Future<void>.delayed(Duration.zero);

    expect(provider.applications, apps);
    expect(notified, isTrue);
  });

  // Listening to a job's applications updates the list when the stream emits.
  test('listenToJobApplications updates the list when the stream emits', () async {
    final apps = [_app('a1', jobId: 'job9')];

    provider.listenToJobApplications('job9');
    repository.emit(apps);
    await Future<void>.delayed(Duration.zero);

    expect(provider.applications, apps);
  });

  // Starting a new listen cancels the previous subscription without errors.
  test('a new listen cancels the previous subscription', () async {
    provider.listenToStudentApplications('stu1');
    provider.listenToJobApplications('job1');

    repository.emit([_app('a1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.applications, hasLength(1));
  });

  // Only the latest emission is kept when the stream emits several times.
  test('keeps the most recent emission', () async {
    provider.listenToStudentApplications('stu1');

    repository.emit([_app('a1')]);
    await Future<void>.delayed(Duration.zero);
    repository.emit([_app('a1'), _app('a2'), _app('a3')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.applications, hasLength(3));
  });
}