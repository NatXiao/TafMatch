import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

typedef detectionCallback = void Function(Float32List vector);
typedef stateUpdateCallback = void Function();

class CameraService {

  CameraController? cameraController;
  FaceDetector? detector;
  bool detectionRequested = false;

  String? cameraError;


  Future<void> initCameraAndDetector(detectionCallback callback, stateUpdateCallback _stateUpdateCallback) async {

    detector = await FaceDetector.create(model: FaceDetectionModel.frontCamera);

    final cameras = await availableCameras();
    for (var c in cameras) {
      if (c.lensDirection == CameraLensDirection.front) {
        cameraController = CameraController(c, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      }
    }
    
    await cameraController!.initialize()
      .then((_) {})
      .catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              print("INIT : NO ACCESS");
              cameraError = "Camera Access Denied !";
              _stateUpdateCallback();
              return;
            default:
              print("INIT : FATAL ERROR");
              cameraError = "An error occured with camera !";
              _stateUpdateCallback();
              return;
          }
        }
      });

    await cameraController!.startImageStream(((image) => _processImage(image, callback, _stateUpdateCallback)));
  }


  Future<void> _processImage(CameraImage image, detectionCallback callback, stateUpdateCallback _stateUpdateCallback) async {

    if (detectionRequested) {
      detectionRequested = false;
      cameraError = "";

      final faces = await detector!.detectFacesFromCameraImage(
        image,
        mode: FaceDetectionMode.full,
        maxDim: 1280,
      );
      
      if (faces.length > 1) {
        cameraError = "Too many person on the image !";
        _stateUpdateCallback();
      }

      if (faces.isEmpty) {
        cameraError = "No person found on the image !";
        _stateUpdateCallback();
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


  void requestDetection() {
    detectionRequested = true;
  }

  void dispose() {
    cameraController?.dispose();
  }


  CameraController? getCameraController() {
    return cameraController;
  }

}