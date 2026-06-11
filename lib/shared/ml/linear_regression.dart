import 'dart:math' as math;
class LinearRegressionModel {
  double slope = 0.0;
  double intercept = 0.0;

  bool get isTrained => slope != 0 || intercept != 0;

  void train(List<double> yValues) {
    if (yValues.length < 2) {
      slope = 0;
      intercept = yValues.isNotEmpty ? yValues.first : 0;
      return;
    }

    final n = yValues.length;

    
    final xValues = List<double>.generate(
      n,
      (index) => (index + 1).toDouble(),
    );

    final xMean =
        xValues.reduce((a, b) => a + b) / n;

    final yMean =
        yValues.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator +=
          (xValues[i] - xMean) *
          (yValues[i] - yMean);

      denominator +=
          (xValues[i] - xMean) *
          (xValues[i] - xMean);
    }

    if (denominator == 0) {
      slope = 0;
      intercept = yMean;
      return;
    }

    slope = numerator / denominator;
    intercept = yMean - (slope * xMean);
  }

  double predict(int period) {
    return intercept + (slope * period);
  }

  List<double> predictNextPeriods(int count, int currentLength) {
    return List.generate(
      count,
      (index) => predict(currentLength + index + 1),
    );
  }

  List<double> predictAll(int length) {
    return List.generate(
      length,
      (index) => predict(index + 1),
    );
  }

  double calculateMAE(List<double> actual) {
    final predicted = predictAll(actual.length);

    double error = 0;
    for (int i = 0; i < actual.length; i++) {
      error += (actual[i] - predicted[i]).abs();
    }

    return error / actual.length;
  }

  double calculateMSE(List<double> actual) {
  final predicted = predictAll(actual.length);

  double error = 0;

  for (int i = 0; i < actual.length; i++) {
    final diff = actual[i] - predicted[i];
    error += diff * diff;
  }

  return error / actual.length;
}

  double calculateRMSE(List<double> actual) {
    return math.sqrt(calculateMSE(actual));
  }

  double calculateR2(List<double> actual) {
    final predicted = predictAll(actual.length);

    final mean =
        actual.reduce((a, b) => a + b) / actual.length;

    double ssRes = 0;
    double ssTot = 0;

    for (int i = 0; i < actual.length; i++) {
      ssRes += math.pow(actual[i] - predicted[i], 2);
      ssTot += math.pow(actual[i] - mean, 2);
    }

    return ssTot == 0 ? 1 : 1 - (ssRes / ssTot);
  }
}
