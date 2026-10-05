import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

enum TapEvent {
  none,
  tap,
  tracking,
  noPerson,
  noBall,
}

/// Detects a toe/foot-to-ball contact from pose + ball detections.
///
/// The detector is intentionally model-agnostic:
/// - Person detection supplies the pose keypoints.
/// - Football detection supplies the ball bounding box.
/// - The nearest visible ankle/foot keypoint is compared with the ball.
///
/// COCO pose convention:
///   15 = left ankle
///   16 = right ankle
///
/// If Flickit's provided model has explicit toe/foot keypoints, update
/// [_footKeypointIndices] to the model's keypoint indices.
class ToeTapDetector extends ChangeNotifier {
  static const List<int> _footKeypointIndices = [15, 16];

  // Contact is relative to the football radius, making the threshold
  // more robust to camera distance and resolution.
  static const double _contactRadiusMultiplier = 1.25;

  // Once a tap is counted, the foot must move away from the ball before
  // another tap can be counted.
  static const double _releaseRadiusMultiplier = 1.75;

  // Require a short stable contact instead of counting a single noisy frame.
  static const int _minimumContactFrames = 2;

  // Extra safety gap after a count.
  static const int _cooldownFrames = 4;

  // Ignore very low-confidence pose keypoints.
  static const double _minimumKeypointConfidence = 0.35;

  int _tapCount = 0;
  int _contactFrames = 0;
  int _cooldownFramesLeft = 0;
  bool _isInContact = false;
  int _missingBallFrames = 0;
  int _missingPersonFrames = 0;

  int get tapCount => _tapCount;
  bool get isInContact => _isInContact;

  TapEvent process(List<YOLOResult> results) {
    final person = _findPerson(results);
    final ball = _findBall(results);

    if (person == null) {
      _missingPersonFrames++;
      _contactFrames = 0;
      if (_missingPersonFrames > 3) {
        _isInContact = false;
        return TapEvent.noPerson;
      }
      return TapEvent.none;
    }
    _missingPersonFrames = 0;

    if (ball == null) {
      _missingBallFrames++;
      _contactFrames = 0;
      if (_missingBallFrames > 3) {
        _isInContact = false;
        return TapEvent.noBall;
      }
      return TapEvent.none;
    }
    _missingBallFrames = 0;

    final ballCenter = Offset(
      ball.boundingBox.center.dx,
      ball.boundingBox.center.dy,
    );
    final ballRadius = math.max(
      4.0,
      math.min(ball.boundingBox.width, ball.boundingBox.height) / 2.0,
    );

    final foot = _nearestVisibleFoot(person.keypoints);
    if (foot == null) {
      _contactFrames = 0;
      return TapEvent.tracking;
    }

    final distance = (foot.position - ballCenter).distance;
    final contactDistance = ballRadius * _contactRadiusMultiplier;
    final releaseDistance = ballRadius * _releaseRadiusMultiplier;

    if (_cooldownFramesLeft > 0) {
      _cooldownFramesLeft--;
    }

    final touching = distance <= contactDistance;
    final released = distance >= releaseDistance;

    // State machine:
    // FREE -> CONTACTING -> COUNTED/CONTACT
    // COUNTED/CONTACT -> FREE only after a clear separation.
    if (!_isInContact) {
      if (touching) {
        _contactFrames++;
        if (_contactFrames >= _minimumContactFrames &&
            _cooldownFramesLeft == 0) {
          _tapCount++;
          _isInContact = true;
          _contactFrames = 0;
          _cooldownFramesLeft = _cooldownFrames;
          notifyListeners();
          return TapEvent.tap;
        }
      } else {
        _contactFrames = 0;
      }
    } else if (released) {
      _isInContact = false;
      _contactFrames = 0;
    }

    return touching ? TapEvent.tracking : TapEvent.none;
  }

  void reset() {
    _tapCount = 0;
    _contactFrames = 0;
    _cooldownFramesLeft = 0;
    _isInContact = false;
    _missingBallFrames = 0;
    _missingPersonFrames = 0;
    notifyListeners();
  }

  YOLOResult? _findPerson(List<YOLOResult> results) {
    final persons = results
        .where(
          (r) =>
              r.confidence >= 0.35 &&
              _isPersonLabel(r.className) &&
              r.keypoints != null &&
              r.keypoints!.isNotEmpty,
        )
        .toList();

    if (persons.isEmpty) return null;

    persons.sort((a, b) => b.confidence.compareTo(a.confidence));
    return persons.first;
  }

  YOLOResult? _findBall(List<YOLOResult> results) {
    final balls = results
        .where(
          (r) =>
              r.confidence >= 0.25 &&
              _isBallLabel(r.className),
        )
        .toList();

    if (balls.isEmpty) return null;

    balls.sort((a, b) => b.confidence.compareTo(a.confidence));
    return balls.first;
  }

  bool _isPersonLabel(String label) {
    final value = label.toLowerCase().trim();
    return value == 'person' || value == 'player' || value == 'human';
  }

  bool _isBallLabel(String label) {
    final value = label.toLowerCase().trim();
    return value == 'sports ball' ||
        value == 'football' ||
        value == 'soccer ball' ||
        value == 'ball';
  }

  _FootPoint? _nearestVisibleFoot(List<Keypoint>? keypoints) {
    if (keypoints == null || keypoints.isEmpty) return null;

    _FootPoint? best;
    for (final index in _footKeypointIndices) {
      if (index >= keypoints.length) continue;

      final kp = keypoints[index];
      if (kp.confidence < _minimumKeypointConfidence) continue;

      final candidate = _FootPoint(
        position: kp.position,
        confidence: kp.confidence,
      );

      if (best == null || candidate.confidence > best.confidence) {
        best = candidate;
      }
    }

    return best;
  }
}

class _FootPoint {
  const _FootPoint({
    required this.position,
    required this.confidence,
  });

  final Offset position;
  final double confidence;
}
