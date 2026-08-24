import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager/repositories/cloudinary_image_repository.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  test('returns the secure_url on a successful upload', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'secure_url': 'https://cdn.example.com/pic.jpg'}),
        200,
      );
    });
    final repo = CloudinaryImageRepository(
      cloudName: 'demo',
      uploadPreset: 'preset',
      client: client,
    );

    final url = await repo.uploadImage(bytes, 'pic.jpg');

    expect(url, 'https://cdn.example.com/pic.jpg');
  });

  test('posts to the configured cloud with the upload preset', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode({'secure_url': 'https://cdn/x.jpg'}), 200);
    });
    final repo = CloudinaryImageRepository(
      cloudName: 'democloud',
      uploadPreset: 'mypreset',
      client: client,
    );

    await repo.uploadImage(bytes, 'pic.jpg');

    expect(captured.method, 'POST');
    expect(
      captured.url.toString(),
      'https://api.cloudinary.com/v1_1/democloud/image/upload',
    );
    expect(captured.body, contains('mypreset'));
  });

  test('throws when the upload fails', () async {
    final client = MockClient((request) async => http.Response('error', 400));
    final repo = CloudinaryImageRepository(
      cloudName: 'demo',
      uploadPreset: 'preset',
      client: client,
    );

    expect(
      () => repo.uploadImage(bytes, 'pic.jpg'),
      throwsA(isA<Exception>()),
    );
  });
}
