import 'dart:math' as math;

double radiusToSigma(double radius) {
  return radius * 0.57735 + 0.5;
}

/// Constant factor to convert and angle from degrees to radians.
const double kDegrees2Radians = math.pi / 180.0;

/// Constant factor to convert and angle from radians to degrees.
const double kRadians2Degrees = 180.0 / math.pi;

/// Convert [radians] to degrees.
double degrees(double radians) => radians * kRadians2Degrees;

/// Convert [degrees] to radians.
double radians(double degrees) => degrees * kDegrees2Radians;

/// assume p1(x1, y1) is the center,
/// the angle of the line between p1 and p2 rotates from the vertical Y axis line of the coordinates
double angle(num x1, num y1, num x2, num y2) {
  final sx = x1 - x2;
  final sy = y1 - y2;
  final dx = sx.abs();
  final dy = sy.abs();
  final d = math.sqrt(dx * dx + dy * dy);
  double angle = (math.asin(dy / d) / math.pi * 180);

  if (x2 >= x1) {
    if (y2 >= y1) {
      angle = 90 + angle;
    } else {
      angle = 90 - angle;
    }
  } else {
    if (y2 >= y1) {
      angle = -(90 + angle);
    } else {
      angle = -(90 - angle);
    }
  }

  return angle;
}

double aangle(x1, y1, x2, y2) {
  return radians(angle(x1, y1, x2, y2));
}
