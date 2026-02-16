import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/vision_service.dart';
import '../services/tts_service.dart';
import '../widgets/object_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ttsTimer;
  String _lastSpoken = "";

  @override
  void initState() {
    super.initState();
    // Periodically checks detected objects to announce them
    _ttsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _announceObjects();
    });
  }

  void _announceObjects() {
    final visionService = Provider.of<VisionService>(context, listen: false);
    final ttsService = Provider.of<TtsService>(context, listen: false);

    if (visionService.objects.isEmpty) return;

    // Logic to construct a sentence from detected objects
    // Example: "Person, Chair, Door detected."
    final labels = visionService.objects
        .map((e) => e.labels.isNotEmpty ? e.labels.first.text : 'Object')
        .toSet() // Unique
        .join(', ');

    if (labels.isNotEmpty && labels != _lastSpoken) {
      ttsService.speak("I see $labels");
      _lastSpoken = labels;
    }
  }

  @override
  void dispose() {
    _ttsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visionService = Provider.of<VisionService>(context);

    if (visionService.controller == null ||
        !visionService.controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    // Calculate scaling for overlay
    // For simplicity, assuming full screen coverage

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(visionService.controller!),

          if (visionService.objects.isNotEmpty)
            CustomPaint(
              painter: ObjectPainter(
                visionService.objects,
                visionService.controller!.value.previewSize!, // imageSize
                size, // widgetSize
                visionService.controller!.description.sensorOrientation,
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "nav",
                  child: const Icon(Icons.navigation),
                  onPressed: () {
                    // Trigger navigation mode
                    Provider.of<TtsService>(context, listen: false)
                        .speak("Navigation mode activated.");
                  },
                ),
                FloatingActionButton(
                  heroTag: "mic",
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.mic, size: 36),
                  onPressed: () {
                    // Trigger voice command listening
                    // (Would integrate speech_to_text here)
                    Provider.of<TtsService>(context, listen: false)
                        .speak("Listening...");
                  },
                ),
                FloatingActionButton(
                  heroTag: "person",
                  child: const Icon(Icons.person),
                  onPressed: () {
                    // Recognize face specific command
                    Provider.of<TtsService>(context, listen: false)
                        .speak("Scanning for faces.");
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
