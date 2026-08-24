import 'dart:typed_data';

abstract class ImageStorageRepository {
  Future<String> uploadImage(Uint8List bytes, String fileName);
}
