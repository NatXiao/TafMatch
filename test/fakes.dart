import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/services/auth_service.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/repositories/firestore_job_repository.dart';
import 'package:taf_match/models/review_model.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/models/skill_model.dart';
import 'package:taf_match/repositories/firestore_skill_repository.dart';
import 'package:taf_match/models/work_experience_model.dart';
import 'package:taf_match/repositories/firestore_work_experience_repository.dart';

class FakeUser implements User {
  @override
  final String uid;

  FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final StreamController<User?> _controller = StreamController<User?>();
  User? _currentUser;

  String? signInError;
  String? registerError;
  String? signOutError;

  int signOutCallCount = 0;

  Completer<void>? gate;
  Completer<String?>? stringGate;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _controller.stream;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    if (gate != null) await gate!.future;
    return signInError;
  }
  @override
  Future<String?> signOut() async {
    signOutCallCount++;
    return signOutError;
  }


  void dispose() => _controller.close();

  @override
  Future<String?> register(String email, String password) async {
    if (stringGate != null) return await stringGate!.future;
    return registerError;
  }
}


class FakeUserRepository implements FirestoreUserRepository {

 final Map<String, UserModel> _users = {};

  UserModel? lastAddedUser;
  UserModel? lastUpdatedUser;
  String? lastDeletedUserId;
  String? lastUserId;

  UserModel? _userDataFor(String userId) => _users[userId];

  List<UserModel> usersToReturn = [];
  Object? getUsersError;
  Completer<List<UserModel>>? getUsersGate;
  int getUsersCallCount = 0;

  @override
  Future<void> addSkill(String uid, String skill) {
    // TODO: implement addSkill
    throw UnimplementedError();
  }

  @override
  Future<void> createProfile(UserModel user) async{
    lastAddedUser = user;
    _users[user.uid] = user;
  }

  @override
  Future<void> deleteProfile(String uid) {
    // TODO: implement deleteProfile
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getProfile(String uid) async {
    return _userDataFor(uid);
  }

  @override
  Future<void> removeSkill(String uid, String skill) {
    // TODO: implement removeSkill
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    // TODO: implement updateProfile
    throw UnimplementedError();
  }

  @override
  Stream<UserModel?> watchProfile(String uid) {
    // TODO: implement watchProfile
    throw UnimplementedError();
  }

  @override
  Future<List<UserModel>> getUsers() async {
    getUsersCallCount++;

    if (getUsersGate != null) {
      return await getUsersGate!.future;
    }

    if (getUsersError != null) {
      throw getUsersError!;
    }

    return usersToReturn;
  }

  void dispose() {
    _users.clear();
  }

}

class FakeApplicationRepository implements FirestoreApplicationRepository {
  final StreamController<List<Application>> _controller =
      StreamController<List<Application>>.broadcast();

  // Call traces
  Application? lastAppliedApplication;
  String? lastCancelledId;
  String? lastStatusId;
  String? lastStatus;
  int applyCallCount = 0;
  int cancelCallCount = 0;

  // Optional simulated errors
  Object? applyError;
  Object? cancelError;

  @override
  Future<void> apply(Application application) async {
    applyCallCount++;
    lastAppliedApplication = application;
    if (applyError != null) throw applyError!;
  }

  @override
  Future<void> cancel(String applicationId) async {
    cancelCallCount++;
    lastCancelledId = applicationId;
    if (cancelError != null) throw cancelError!;
  }

  @override
  Future<void> updateStatus(String applicationId, String status) async {
    lastStatusId = applicationId;
    lastStatus = status;
  }

  @override
  Stream<List<Application>> watchByStudent(String studentId) => _controller.stream;

  @override
  Stream<List<Application>> watchByJob(String jobId) => _controller.stream;

  // Emit data into the provider during a test
  void emit(List<Application> apps) => _controller.add(apps);

  void dispose() => _controller.close();
}

class FakeJobRepository implements FirestoreJobRepository {
  final StreamController<List<Job>> _controller =
      StreamController<List<Job>>.broadcast();

  // What create() will return, and what getById() will find
  String createIdToReturn = 'generated-id';
  final Map<String, Job> jobsById = {};

  // Call traces
  Job? lastCreatedJob;
  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedFields;
  String? lastDeletedId;
  int createCallCount = 0;

  // Optional simulated errors
  Object? createError;

  @override
  Future<String> create(Job job) async {
    createCallCount++;
    lastCreatedJob = job;
    if (createError != null) throw createError!;
    return createIdToReturn;
  }

  @override
  Future<Job?> getById(String id) async => jobsById[id];

  @override
  Stream<List<Job>> watchLiveJobs() => _controller.stream;

  @override
  Stream<List<Job>> watchByEmployer(String employerId) => _controller.stream;

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    lastUpdatedId = id;
    lastUpdatedFields = fields;
  }

  @override
  Future<void> delete(String id) async {
    lastDeletedId = id;
  }

  // Emit data into the provider during a test
  void emit(List<Job> jobs) => _controller.add(jobs);

  void dispose() => _controller.close();
}


class FakeReviewRepository implements FirestoreReviewRepository {
  final StreamController<List<Review>> _controller =
      StreamController<List<Review>>.broadcast();

  // Call traces
  Review? lastCreatedReview;
  String? lastDeletedId;
  int createCallCount = 0;

  // Optional simulated errors
  Object? createError;

  @override
  Future<void> create(Review review) async {
    createCallCount++;
    lastCreatedReview = review;
    if (createError != null) throw createError!;
  }

  @override
  Future<void> delete(String id) async {
    lastDeletedId = id;
  }

  @override
  Stream<List<Review>> watchForUser(String targetUserId) => _controller.stream;

  // Emit data into the provider during a test
  void emit(List<Review> reviews) => _controller.add(reviews);

  void dispose() => _controller.close();
}


class FakeSkillRepository implements FirestoreSkillRepository {
  List<Skill> skillsToReturn = [];
  Object? getAllError;
  Completer<List<Skill>>? getAllGate;
  int getAllCallCount = 0;

  @override
  Future<List<Skill>> getAll() async {
    getAllCallCount++;
    if (getAllGate != null) return await getAllGate!.future;
    if (getAllError != null) throw getAllError!;
    return skillsToReturn;
  }

  @override
  Future<void> seed(List<String> names) async {
    // Not needed for these tests.
  }
}


class FakeWorkExperienceRepository implements FirestoreWorkExperienceRepository {
  final StreamController<List<WorkExperience>> _controller =
      StreamController<List<WorkExperience>>.broadcast();

  // Call traces
  String? lastAddedUid;
  WorkExperience? lastAddedExperience;
  String? lastDeletedUid;
  String? lastDeletedId;
  int addCallCount = 0;
  int deleteCallCount = 0;

  // Optional simulated errors
  Object? addError;
  Object? deleteError;

  @override
  Future<void> add(String uid, WorkExperience exp) async {
    addCallCount++;
    lastAddedUid = uid;
    lastAddedExperience = exp;
    if (addError != null) throw addError!;
  }

  @override
  Future<void> delete(String uid, String experienceId) async {
    deleteCallCount++;
    lastDeletedUid = uid;
    lastDeletedId = experienceId;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Stream<List<WorkExperience>> watchForUser(String uid) => _controller.stream;

  // Emit data into the provider during a test
  void emit(List<WorkExperience> experiences) => _controller.add(experiences);

  void dispose() => _controller.close();
}