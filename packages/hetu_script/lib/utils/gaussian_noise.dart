import "dart:math";

// Box–Muller transform for generating normally distributed random numbers

double gaussianNoise(double mean, double standardDeviation,
    {Random? randomGenerator}) {
  const double pi2 = pi * 2.0;

  randomGenerator ??= Random();

  double r1 = randomGenerator.nextDouble();
  double r2 = randomGenerator.nextDouble();

  bool quadrant = randomGenerator.nextBool();

  return quadrant
      ? sqrt(-2.0 * log(r1)) * cos(pi2 * r2) * standardDeviation + mean
      : sqrt(-2.0 * log(r1)) * sin(pi2 * r2) * standardDeviation + mean;
}
