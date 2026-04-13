/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../data.dart';

/// Store and retrieve data streams for study deployments.
abstract class DataStreamService {
  static const String API_VERSION = "1.1";

  /// Start accepting data for a study deployment for data streams configured
  /// in [configuration].
  ///
  /// Throws IllegalStateException when data streams for the specified study
  /// deployment have already been configured.
  Future<void> openDataStreams(DataStreamsConfiguration configuration);

  /// Append a [batch] of data measures to corresponding data streams
  /// in [studyDeploymentId].
  ///
  /// Throws IllegalArgumentException when:
  ///  - the `studyDeploymentId` of one or more sequences in [batch] does not
  ///    match [studyDeploymentId]
  ///  - the start of one or more of the sequences contained in [batch]
  ///    precede the end of a previously appended sequence to the same data stream
  ///  - [batch] contains a sequence with [DataStreamId] which wasn't configured
  ///    for [studyDeploymentId]
  ///
  /// Throws IllegalStateException when data streams for [studyDeploymentId]
  /// have been closed.
  Future<void> appendToDataStreams(
    String studyDeploymentId,
    List<DataStreamBatch> batch,
  );

  /// Retrieve all data points in [dataStream] that fall within the inclusive range
  /// defined by [fromSequenceId] and [toSequenceIdInclusive].
  /// If [toSequenceIdInclusive] is null, all data points starting [fromSequenceId]
  /// are returned.
  ///
  /// In case no data for [dataStream] is stored in this repository, or is
  /// available for the specified range, an empty list is returned.
  ///
  /// Throws IllegalArgumentException if:
  ///  - [dataStream] has never been opened
  ///  - the [dataStream] does not exist (i.e, that the combination of [dataStream.deviceRoleName]
  ///    and [dataStream.dataType] is correct for the protocol used in the
  ///    [dataStream.studyDeploymentId] deployment.)
  ///  - [fromSequenceId] is negative or [toSequenceIdInclusive] is smaller
  ///    than [fromSequenceId]
  Future<List<DataStreamBatch>> getDataStream(
    DataStreamId dataStream,
    int fromSequenceId, [
    int? toSequenceIdInclusive,
  ]);

  /// Stop accepting incoming data for all data streams for each of the [studyDeploymentIds].
  ///
  /// Throws IllegalArgumentException when no data streams were ever opened for
  /// any of the [studyDeploymentIds].
  Future<void> closeDataStreams(List<String> studyDeploymentIds);

  /// Close data streams and remove all data for each of the [studyDeploymentIds].
  ///
  /// Returns the IDs of the study deployments for which data streams were configured.
  /// IDs for which no study deployment exists are ignored.
  Future<Set<String>> removeDataStreams(List<String> studyDeploymentIds);
}
