import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/user_model.dart';

void main() {

  test('fromMap allows a missing pictures', () {
    final user = UserModel.fromMap(
      "uuid",
      {
        "email": "user@test.ch",
        "fullname": "test",
        "role": "student",
        "address": "12 test"
      }
    );

    expect(user.profilePictureUrl, "");
    expect(user.pictureRecognition, "");
  });
  
}
