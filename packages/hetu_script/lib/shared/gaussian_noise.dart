import "dart:math";

// Box–Muller transform for generating normally distributed random numbers
late double _z0, _z1;
bool _generate = true;

double gaussianNoise(double mean, double standardDeviation,
    {Random? randomGenerator}) {
  const double pi2 = pi * 2.0;

  _generate = !_generate;

  if (_generate) {
    return _z1;
  }

  randomGenerator ??= Random();

  double r1 = randomGenerator.nextDouble();
  double r2 = randomGenerator.nextDouble();

  _z0 = sqrt(-2.0 * log(r1)) * cos(pi2 * r2) * standardDeviation + mean;
  _z1 = sqrt(-2.0 * log(r1)) * sin(pi2 * r2) * standardDeviation + mean;
  return _z0;
}
