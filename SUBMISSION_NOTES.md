# Flickit Submission Checklist

Before submitting:

[ ] Add the Flickit-provided YOLO Pose model.
[ ] Update modelPath in lib/src/app_config.dart.
[ ] Confirm ball class label.
[ ] Confirm toe/foot keypoint indices.
[ ] Run `flutter pub get`.
[ ] Run `flutter analyze`.
[ ] Run `flutter test`.
[ ] Run on a physical phone with camera permission.
[ ] Test at least 10 taps.
[ ] Verify one tap increments only once.
[ ] Verify Reset returns the counter to 0.
[ ] Capture a short screen recording for the assignment.

## Demo script

Start app → show camera → press Start → perform 5 toe taps → show
`Toe Taps: 5` → press Reset → show `Toe Taps: 0`.

## Key design decision

The counter uses a contact/release state machine instead of frame counting.
That is the main anti-duplicate mechanism in this implementation.
