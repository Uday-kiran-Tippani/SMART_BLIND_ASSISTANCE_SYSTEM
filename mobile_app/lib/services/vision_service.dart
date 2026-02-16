import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/services.dart';

class VisionService extends ChangeNotifier {
  CameraController? _controller;
  ObjectDetector? _objectDetector;
  final bool _isDetecting = false;
  List<DetectedObject> _detectedObjects = [];
  bool _isProcessing = false;

  final List<CameraDescription> cameras;

  VisionService(this.cameras) {
    _initializeCamera();
    _initializeDetector();
  }

  CameraController? get controller => _controller;
  List<DetectedObject> get objects => _detectedObjects;
  bool get isDetecting => _isDetecting;

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0], // Use back camera
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      notifyListeners();
      _startImageStream();
    } catch (e) {
      debugPrint("Camera initialize error: $e");
    }
  }

  void _initializeDetector() {
    // robust mode for general objects
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final objects = await _objectDetector!.processImage(inputImage);
      _detectedObjects = objects;
      notifyListeners();
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // Simple logic for input image creation (simplified for this snippet)
    // Often requires complex rotation logic based on platform
    // For now assuming standard portrait orientation
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    const InputImageRotation imageRotation =
        InputImageRotation.rotation90deg; // Common for portrait

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector?.close();
    super.dispose();
  }
}
