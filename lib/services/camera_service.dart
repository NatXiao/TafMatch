import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:flutter/widgets.dart';

typedef DetectionCallback = void Function(Float32List vector);

class CameraService extends ChangeNotifier {

  CameraController? cameraController;
  FaceDetector? detector;
  bool detectionRequested = false;
  bool streamStarted = false;

  String? cameraError;

  /// Initialize camera and launch streaming
  void initCameraAndDetector(DetectionCallback callback) async {

    detector = await FaceDetector.create(model: FaceDetectionModel.frontCamera);

    final cameras = await availableCameras();
    for (var c in cameras) {
      if (c.lensDirection == CameraLensDirection.front) {
        cameraController = CameraController(c, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      }
    }
    
    await cameraController!.initialize()
      .then((_) {})
      .catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              cameraError = "Camera Access Denied !";
              notifyListeners();
              return;
            default:
              cameraError = "An error occured with camera !";
              notifyListeners();
              return;
          }
        }
      });

    await cameraController!.startImageStream(((image) => _processImage(image, callback)));
    notifyListeners();
  }

  Future<void> _processImage(CameraImage image, DetectionCallback callback) async {

    streamStarted = true;

    if (detectionRequested) {
      detectionRequested = false;
      cameraError = "";

      final faces = await detector!.detectFacesFromCameraImage(
        image,
        mode: FaceDetectionMode.standard,
        maxDim: 640,
      );
      
      if (faces.length > 1) {
        cameraError = "Too many person on the image !";
        notifyListeners();
      }

      if (faces.isEmpty) {
        cameraError = "No person found on the image !";
        notifyListeners();
      }

      if (faces.length == 1) {

        final image = await cameraController?.takePicture();
        final bytes = await image?.readAsBytes();

        if (bytes != null) {
          final embedding = await detector!.getFaceEmbedding(faces[0], bytes);

          callback(embedding);

        }

      }

    }

  }

  /// Request a detection of face in the camera
  void requestDetection() {
    detectionRequested = true;
  }

  @override
  void dispose() {
    if (streamStarted == true) cameraController?.stopImageStream();
    cameraController?.dispose();
    super.dispose();
  }

  CameraController? getCameraController() {
    return cameraController;
  }

}