/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// Ambient light intensity in Lux.
/// Typically collected from the light sensor on the front of the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AmbientLight extends SensorData {
  num meanLux;
  num stdLux;
  num minLux;
  num maxLux;

  AmbientLight(this.meanLux, this.stdLux, this.minLux, this.maxLux) : super();

  /// Create an [AmbientLight] from a list of lux value readings.
  factory AmbientLight.fromLuxReadings(List<num> luxValues) {
    var statistics = luxValues.statistics;
    return AmbientLight(
      statistics.mean,
      statistics.standardDeviation,
      statistics.min,
      statistics.max,
    );
  }

  @override
  Function get fromJsonFunction => _$AmbientLightFromJson;
  factory AmbientLight.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AmbientLight>(json);
  @override
  Map<String, dynamic> toJson() => _$AmbientLightToJson(this);
}

/// A set of acceleration (non-gravitational) features collected over a specific
/// sampling period.
///
/// The set of features is inspired from the Medium article on
/// [Feature Engineering on Time-Series Data for Human Activity Recognition](https://medium.com/towards-data-science/feature-engineering-on-time-series-data-transforming-signal-data-of-a-smartphone-accelerometer-for-72cbe34b8a60)
/// and contains the following 15 simple statistical features:
///   1. mean
///   2. standard deviation
///   3. average absolute deviation
///   4. minimum value
///   5. maximum value
///   6. difference of maximum and minimum values
///   7. median
///   8. median absolute deviation
///   9. inter-quartile range
///  10. negative values count
///  11. positive values count
///  12. number of values above mean
///  13. energy
///  14. average resultant acceleration
///  15. signal magnitude area
///
/// Most of these features are self-explanatory, except:
///
///  * Energy of a signal in every axis is computed by taking the mean of sum
///    of squares of the values in a window in that particular axis.
///  * Average resultant acceleration over the window is computed by taking
///    average of the square roots of the values in each of the three axis squared
///    and added together.
///  * Signal magnitude area is defined as the sum of absolute values of the
///    three axis averaged over a window.
///
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccelerationFeatures extends SensorData {
  int count = 0;
  num? xMean,
      yMean,
      zMean,
      xStd,
      yStd,
      zStd,
      xAad,
      yAad,
      zAad,
      xMin,
      yMin,
      zMin,
      xMax,
      yMax,
      zMax,
      xMaxMinDiff,
      yMaxMinDiff,
      zMaxMinDiff,
      xMedian,
      yMedian,
      zMedian,
      xMad,
      yMad,
      zMad,
      xIqr,
      yIqr,
      zIqr,
      xNegCount,
      yNegCount,
      zNegCount,
      xPosCount,
      yPosCount,
      zPosCount,
      xAboveMean,
      yAboveMean,
      zAboveMean,
      // xPeakCount,
      // yPeakCount,
      // zPeakCount,
      // xSkewness,
      // ySkewness,
      // zSkewness,
      // xKurtosis,
      // yKurtosis,
      // zKurtosis,
      xEnergy,
      yEnergy,
      zEnergy,
      avgResultAcceleration,
      signalMagnitudeArea;

  AccelerationFeatures() : super();

  factory AccelerationFeatures.fromAccelerometerReadings(
    List<UserAccelerometerEvent> readings,
  ) {
    final n = readings.length;

    final List<num> xList = readings.map((event) => event.x).toList();
    final List<num> yList = readings.map((event) => event.y).toList();
    final List<num> zList = readings.map((event) => event.z).toList();

    final xStatistics = xList.statistics;
    final yStatistics = yList.statistics;
    final zStatistics = zList.statistics;

    final xStats = Stats(xList);
    final yStats = Stats(yList);
    final zStats = Stats(zList);

    var features = AccelerationFeatures()
      ..count = n
      // mean
      ..xMean = xStatistics.mean
      ..yMean = yStatistics.mean
      ..zMean = zStatistics.mean
      // std dev
      ..xStd = xStatistics.standardDeviation
      ..yStd = yStatistics.standardDeviation
      ..zStd = zStatistics.standardDeviation
      //min
      ..xMin = xStatistics.min
      ..yMin = yStatistics.min
      ..zMin = zStatistics.min
      // max
      ..xMax = xStatistics.max
      ..yMax = yStatistics.max
      ..zMax = zStatistics.max
      //max-min diff
      ..xMaxMinDiff = xStatistics.max - xStatistics.min
      ..yMaxMinDiff = yStatistics.max - yStatistics.min
      ..zMaxMinDiff = zStatistics.max - zStatistics.min
      // median
      ..xMedian = xStatistics.median
      ..yMedian = yStatistics.median
      ..zMedian = zStatistics.median
      // energy
      ..xEnergy = xStatistics.squaresSum / n
      ..yEnergy = yStatistics.squaresSum / n
      ..zEnergy = zStatistics.squaresSum / n
    //
    ;

    // positive count
    features.xPosCount = xList.where((x) => x > 0).length;
    features.yPosCount = yList.where((y) => y > 0).length;
    features.zPosCount = zList.where((z) => z > 0).length;

    // negative count
    features.xNegCount = xList.where((x) => x < 0).length;
    features.yNegCount = yList.where((y) => y < 0).length;
    features.zNegCount = zList.where((z) => z < 0).length;

    // inter-quartile range
    features.xIqr = xStats.quartile3 - xStats.quartile1;
    features.yIqr = yStats.quartile3 - yStats.quartile1;
    features.zIqr = zStats.quartile3 - zStats.quartile1;

    // values above mean
    features.xAboveMean = xList.where((x) => x > xStatistics.mean).length;
    features.yAboveMean = yList.where((y) => y > yStatistics.mean).length;
    features.zAboveMean = zList.where((z) => z > zStatistics.mean).length;

    // average absolute diff (AAD)
    // median abs dev (MAD)
    // average results
    // signal magnitude area (SMA)
    List<num> ar = [];
    num xSma = 0, ySma = 0, zSma = 0;
    List<num> xAad = [], yAad = [], zAad = [];
    List<num> xMad = [], yMad = [], zMad = [];
    for (var r in readings) {
      xAad.add((r.x - xStatistics.mean).abs());
      yAad.add((r.y - yStatistics.mean).abs());
      zAad.add((r.z - zStatistics.mean).abs());

      xMad.add((r.x - xStatistics.median).abs());
      yMad.add((r.y - yStatistics.median).abs());
      zMad.add((r.z - zStatistics.median).abs());

      ar.add(math.sqrt(math.pow(r.x, 2) + math.pow(r.y, 2) + math.pow(r.z, 2)));

      xSma += r.x.abs() / n;
      ySma += r.y.abs() / n;
      zSma += r.z.abs() / n;
    }
    features.xAad = xAad.mean;
    features.yAad = yAad.mean;
    features.zAad = zAad.mean;
    features.xMad = xMad.median;
    features.yMad = yMad.median;
    features.zMad = zMad.median;
    features.avgResultAcceleration = ar.mean;
    features.signalMagnitudeArea = xSma + ySma + zSma;

    return features;
  }

  @override
  Function get fromJsonFunction => _$AccelerationFeaturesFromJson;
  factory AccelerationFeatures.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AccelerationFeatures>(json);
  @override
  Map<String, dynamic> toJson() => _$AccelerationFeaturesToJson(this);
}

/// Step event data as sensed by the phone's built-in pedometer.
///
/// Normally, a step event is sent for each step taken by the user.
/// But note that this depends on the underlying OS and hardware capabilities.
/// [steps] is the number of steps taken since last reboot of the device.
/// This number is accumulated by the OS and not reset when the app is restarted.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StepEvent extends SensorData {
  /// Number of steps accumulated since last reboot of the device.
  int steps;

  StepEvent({this.steps = 0}) : super();

  @override
  Function get fromJsonFunction => _$StepEventFromJson;
  factory StepEvent.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StepEvent>(json);
  @override
  Map<String, dynamic> toJson() => _$StepEventToJson(this);
}
