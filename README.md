# Flickit Software Engineer Intern Assignment
## Flutter + Computer Vision: Toe Tap Counter

A Flutter mobile app that uses the official Ultralytics YOLO Flutter plugin for
real-time camera inference and a small geometry/state-machine layer to count
football toe taps.

### Pipeline

Camera
  ↓
Ultralytics YOLO Pose
  ↓
Person + pose keypoints + football
  ↓
Foot-to-ball distance
  ↓
Contact state machine
  ↓
Toe Taps counter

## Important model note

The assignment says Flickit provides the required YOLO Pose model. That model is
not included in this archive because it was not attached to the request.

The app is already wired for the model. Put the supplied Android-compatible
`.tflite` model in:

`assets/models/`

Then change `modelPath` in:

`lib/src/app_config.dart`

to the exact asset path.

Example:

```dart
static const String modelPath = 'assets/models/flickit_pose.tflite';
static const YOLOTask modelTask = YOLOTask.pose;
```

If the supplied model has pose metadata and class labels, the app reads its
results directly.

## How toe taps are detected

The detector does not simply count "foot is near ball" on every frame.

1. Find the highest-confidence person detection.
2. Read left/right ankle keypoints (COCO indices 15 and 16).
3. Find the highest-confidence football detection.
4. Calculate the distance from the visible foot keypoint to the football center.
5. Consider contact when the distance is within `1.25 × ball radius`.
6. Require two consecutive contact frames.
7. Count exactly once.
8. Lock the state until the foot moves at least `1.75 × ball radius` away.
9. Add a small cooldown to prevent frame-to-frame duplicate counts.

This makes the counter behave like:

Tap → release → Tap → release

rather than:

contact frame 1 → contact frame 2 → contact frame 3 → ... = many taps.

### If Flickit's model has toe keypoints

The default code uses COCO ankle indices:

- 15 = left ankle
- 16 = right ankle

If the provided model exposes explicit toe/foot keypoints, change:

```dart
static const List<int> _footKeypointIndices = [15, 16];
```

to the correct indices from the provided model.

## Ball labels supported

The detector recognizes:

- `sports ball`
- `football`
- `soccer ball`
- `ball`

If the supplied model uses another class name, add it in
`_isBallLabel()`.

## Setup

### 1. Install prerequisites

- Flutter SDK
- Android Studio
- Android SDK / emulator or physical Android phone
- USB debugging enabled for a physical phone

Check:

```bash
flutter doctor
```

### 2. Generate platform folders

This archive contains the Flutter application source. If `android/` and `ios/`
are not present in your checkout, run:

```bash
flutter create .
```

This creates the standard Android/iOS runner projects without changing the
`lib/` implementation.

### 3. Install packages

```bash
flutter pub get
```

### 4. Add Flickit's model

Copy the supplied model to:

```text
assets/models/
```

Update:

```text
lib/src/app_config.dart
```

### 5. Run

```bash
flutter devices
flutter run
```

For Android:

```bash
flutter run -d <device-id>
```

### 6. Test the flow

1. Open the app.
2. Allow camera permission.
3. Confirm the model-loaded indicator.
4. Press Start.
5. Put the football and lower legs in view.
6. Tap the football with the toe/foot.
7. Move the foot away.
8. Repeat.
9. The HUD should show:

```text
Toe Taps: 5
```

for five taps.

## Project structure

```text
flickit_toe_tap_counter/
├── assets/
│   └── models/
│       └── PUT_FLICKIT_MODEL_HERE.txt
├── lib/
│   ├── main.dart
│   └── src/
│       ├── app_config.dart
│       └── toe_tap_detector.dart
├── test/
│   └── toe_tap_detector_test.dart
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

## Why this implementation is suitable for the assignment

- Flutter/Dart UI
- Real-time camera inference
- Official Ultralytics Flutter integration
- Pose keypoint usage
- Football detection
- Geometry-based contact detection
- Frame-level debouncing/state machine
- Start / Reset flow
- Confidence thresholds
- GPU inference enabled
- Separation logic prevents repeated counting
- Model-specific assumptions are isolated in one detector/config file

## Interview explanation

### Problem statement

The application needs to convert noisy frame-by-frame computer-vision
predictions into a reliable event: one physical foot-to-ball contact equals one
count.

### Proposed solution

I use YOLO Pose to obtain the player and pose keypoints and identify the
football. I calculate the distance between the foot/ankle keypoint and the
football center using a threshold based on the football radius. A state machine
then requires stable contact before incrementing the counter and requires the
foot to move away before another tap can be counted.

### Why not count every contact frame?

A camera may produce 20–30 inference frames while the foot is touching the ball
once. Counting every frame would turn one physical tap into many taps. The
contact/release state machine solves this.

### Complexity

The event-processing code is O(n) per inference frame, where n is the number of
YOLO results. The number of person/ball detections is small in this use case.

## Dependency

The app uses:

`ultralytics_yolo: ^0.6.15`

The official Ultralytics Flutter plugin supports real-time `YOLOView`, pose
estimation, custom models, confidence/IoU thresholds, and Android/iOS camera
inference.

For the actual submission, use the model supplied by Flickit and verify the
exact keypoint/class labels against that model before recording the demo.
