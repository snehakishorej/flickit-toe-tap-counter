import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import 'src/app_config.dart';
import 'src/toe_tap_detector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlickitToeTapApp());
}

class FlickitToeTapApp extends StatelessWidget {
  const FlickitToeTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flickit Toe Tap Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ToeTapHomePage(),
    );
  }
}

class ToeTapHomePage extends StatefulWidget {
  const ToeTapHomePage({super.key});

  @override
  State<ToeTapHomePage> createState() => _ToeTapHomePageState();
}

class _ToeTapHomePageState extends State<ToeTapHomePage> {
  final YOLOViewController _yoloController = YOLOViewController();
  final ToeTapDetector _detector = ToeTapDetector();

  bool _started = false;
  bool _modelLoaded = false;
  String _status = 'Press Start to begin';
  double _fps = 0;

  @override
  void initState() {
    super.initState();
    _detector.addListener(_onDetectorChanged);
  }

  void _onDetectorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detector.removeListener(_onDetectorChanged);
    _detector.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _status = 'Camera active. Perform toe taps.';
    });
  }

  Future<void> _reset() async {
    _detector.reset();
    await _yoloController.restartCamera();
    if (mounted) {
      setState(() {
        _started = false;
        _status = 'Reset. Press Start to begin.';
        _fps = 0;
      });
    }
  }

  void _onResults(List<YOLOResult> results) {
    if (!_started) return;

    final event = _detector.process(results);

    if (mounted) {
      setState(() {
        if (event == TapEvent.tap) {
          _status = 'Toe tap detected!';
        } else if (event == TapEvent.noPerson) {
          _status = 'Move into camera view.';
        } else if (event == TapEvent.noBall) {
          _status = 'Place the football in view.';
        } else if (event == TapEvent.tracking) {
          _status = 'Tracking foot + ball...';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flickit • Toe Tap Counter'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: YOLOView(
                    modelPath: AppConfig.modelPath,
                    task: AppConfig.modelTask,
                    controller: _yoloController,
                    cameraResolution: '720p',
                    confidenceThreshold: AppConfig.confidenceThreshold,
                    iouThreshold: AppConfig.iouThreshold,
                    useGpu: true,
                    onResult: _onResults,
                    onPerformanceMetrics: (metrics) {
                      if (mounted) {
                        setState(() => _fps = metrics.fps);
                      }
                    },
                    onModelLoad: (_, __) {
                      if (mounted) {
                        setState(() {
                          _modelLoaded = true;
                          _status = _started
                              ? 'Camera active. Perform toe taps.'
                              : 'Model loaded. Press Start.';
                        });
                      }
                    },
                    onModelError: (error, path, task) {
                      if (mounted) {
                        setState(() {
                          _modelLoaded = false;
                          _status = 'Model error: $error';
                        });
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _TopHud(
                    count: _detector.tapCount,
                    fps: _fps,
                    modelLoaded: _modelLoaded,
                  ),
                ),
                if (!_started)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Text(
                              'START',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _started ? null : _start,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.count,
    required this.fps,
    required this.modelLoaded,
  });

  final int count;
  final double fps;
  final bool modelLoaded;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.78),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Toe Taps:',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${fps.toStringAsFixed(0)} FPS',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(width: 8),
            Icon(
              modelLoaded ? Icons.check_circle : Icons.pending,
              color: modelLoaded ? Colors.greenAccent : Colors.orangeAccent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
