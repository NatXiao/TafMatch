import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'image_storage_repository.dart';

class CloudinaryImageRepository implements ImageStorageRepository {
  final String cloudName;
  final String uploadPreset;
  final http.Client _client;

  CloudinaryImageRepository({
    required this.cloudName,
    required this.uploadPreset,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Image upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
