import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/services/auth_service.dart';

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
  Future<String?> signOut() async => signOutError;

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

  @override
  Future<void> addSkill(String uid, String skill) {
    // TODO: implement addSkill
    throw UnimplementedError();
  }

  @override
  Future<void> createProfile(UserModel user) {
    lastAddedUser = user;
    _users[user.uid] = user;
    return Future<void>.delayed(Duration.zero);
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

  void dispose() {
    _users.clear();
  }

}
