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
