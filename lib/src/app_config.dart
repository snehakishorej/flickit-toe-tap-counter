import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Central configuration for the assignment.
///
/// IMPORTANT:
/// Replace [modelPath] with the exact model supplied by Flickit.
/// Android: a .tflite asset can be placed in assets/models/.
/// iOS: use the compatible Core ML export as documented by Ultralytics.
class AppConfig {
  AppConfig._();

  // If Flickit gives you a packaged TFLite model, use:
  // static const modelPath = 'assets/models/flickit_pose.tflite';
  //
  // The project currently uses an official model ID so the project can
  // start without bundling a large model. For the actual assignment,
  // replace this with the provided Flickit model.
  static const String modelPath = 'yolo26n-pose';

  static const YOLOTask modelTask = YOLOTask.pose;

  static const double confidenceThreshold = 0.35;
  static const double iouThreshold = 0.45;
}
