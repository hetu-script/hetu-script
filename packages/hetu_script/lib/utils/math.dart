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

// Box–Muller transform for generating normally distributed random numbers
double gaussianNoise(double mean, double standardDeviation,
    {math.Random? randomGenerator}) {
  const double pi2 = math.pi * 2.0;

  randomGenerator ??= math.Random();

  double r1 = randomGenerator.nextDouble();
  double r2 = randomGenerator.nextDouble();

  bool quadrant = randomGenerator.nextBool();

  return quadrant
      ? math.sqrt(-2.0 * math.log(r1)) *
              math.cos(pi2 * r2) *
              standardDeviation +
          mean
      : math.sqrt(-2.0 * math.log(r1)) *
              math.sin(pi2 * r2) *
              standardDeviation +
          mean;
}

/// Input a value and a target, get a output between 0.0 and 1.0.
/// The more the input is near the target, the more the output is near 1.0.
double gradualValue(num input, num target, {double power = 0.1}) {
  assert(input >= 0 && input <= target);
  final ratio = input / target;
  return math.pow(ratio, 1 / power).toDouble();
}

extension RandomEx on math.Random {
  bool nextBoolBiased(double input, double target) {
    if (input >= target) {
      return true;
    } else {
      final difference = (input - target).abs();
      final probability = 1 - (difference / target);
      return nextDouble() <= probability;
    }
  }

  int nearInt(int max, {double exponent = 0.5}) {
    return (max * math.pow(nextDouble(), exponent)).toInt();
  }

  int distantInt(int max, {double exponent = 0.5}) {
    return (max * (1 - math.pow(nextDouble(), exponent))).toInt();
  }

  String nextColorHex({bool hasAlpha = false}) {
    var prefix = '#';
    if (hasAlpha) {
      prefix += 'ff';
    }
    return prefix +
        (nextDouble() * 16777215).truncate().toRadixString(16).padLeft(6, '0');
  }

  String nextBrightColorHex({bool hasAlpha = false}) {
    var prefix = '#';
    if (hasAlpha) {
      prefix += 'ff';
    }
    return prefix +
        (nextDouble() * 5592405 + 11184810)
            .truncate()
            .toRadixString(16)
            .padLeft(6, '0');
  }

  dynamic nextIterable(Iterable iterable) {
    if (iterable.isNotEmpty) {
      return iterable.elementAt(nextInt(iterable.length));
    } else {
      return null;
    }
  }
}
