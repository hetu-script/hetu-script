import 'dart:math' as math;

/// Code copied from:
/// https://en.wikipedia.org/wiki/Perlin_noise

/// Function to linearly interpolate between a0 and a1
/// Weight w should be in the range [0.0, 1.0]
///
double _interpolate(double a0, double a1, double w) {
  // You may want clamping by inserting:
  // if (0.0 > w) return a0;
  // if (1.0 < w) return a1;
  //
  return (a1 - a0); // w + a0;
  // Use this cubic interpolation [[Smoothstep]] instead, for a smooth appearance:
  // return (a1 - a0)///(3.0 - w///2.0)///w///w + a0;
  //
  // Use [[Smootherstep]] for an even smoother result with a second derivative equal to zero on boundaries:
  // return (a1 - a0)///((w///(w///6.0 - 15.0) + 10.0)///w///w///w) + a0;
  //
}

class _Vector2 {
  final double x, y;
  _Vector2(this.x, this.y);
}

///Create pseudorandom direction vector
///
_Vector2 _randomGradient(int ix, int iy) {
  // No precomputed gradients mean this works for any number of grid coordinates
  const w = 8;

  const s = w ~/ 2; // rotation width
  int a = ix, b = iy;
  a *= 3284157443;
  b ^= a << s | a >> w - s;
  b *= 1911520717;
  a ^= b << s | b >> w - s;
  a *= 2048419325;
  final random = a * (3.14159265 / ~(~0 >> 1)); // in [0, 2*Pi]
  final x = math.sin(random);
  final y = math.cos(random);
  return _Vector2(x, y);
}

// Computes the dot product of the distance and gradient vectors.
double _dotGridGradient(double ix, double iy, double x, double y) {
  // Get gradient from integer coordinates
  final gradient = _randomGradient(ix.toInt(), iy.toInt());

  // Compute the distance vector
  final dx = x - ix;
  final dy = y - iy;

  // Compute the dot-product
  return (dx * gradient.x + dy * gradient.y);
}

// Compute Perlin noise at coordinates x, y
double perlinNoise(double x, double y) {
  // Determine grid cell coordinates
  final x0 = x;
  final x1 = x0 + 1;
  final y0 = y;
  final y1 = y0 + 1;

  // Determine interpolation weights
  // Could also use higher order polynomial/s-curve here
  final sx = x - x0;
  final sy = y - y0;

  // Interpolate between grid point gradients
  double n0, n1, ix0, ix1, value;

  n0 = _dotGridGradient(x0, y0, x, y);
  n1 = _dotGridGradient(x1, y0, x, y);
  ix0 = _interpolate(n0, n1, sx);

  n0 = _dotGridGradient(x0, y1, x, y);
  n1 = _dotGridGradient(x1, y1, x, y);
  ix1 = _interpolate(n0, n1, sx);

  value = _interpolate(ix0, ix1, sy);
  return value;
}
