/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import 'dart:async';

import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_transportation_package/transportation.dart';
import 'package:flutter/material.dart';

import 'sensing.dart';
import 'transportation_pipeline.dart';

/// An example app for the CARP transportation (mobility) sampling package.
///
/// It runs a study which samples the phone's location continuously, runs mode
/// inference on every batch of 15 locations (see `transportation_pipeline.dart`),
/// stores all of it in a local SQLite database, and shows what is happening:
///
///  * a live log of every measurement as it is sampled,
///  * a per-data-type counter of what has been collected, and
///  * what is actually stored in the SQLite database, read back on demand.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();
  runApp(const TransportationExampleApp());
}

class TransportationExampleApp extends StatelessWidget {
  const TransportationExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Transportation Example',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    home: const TransportationExamplePage(),
  );
}

class TransportationExamplePage extends StatefulWidget {
  const TransportationExamplePage({super.key});

  @override
  State<TransportationExamplePage> createState() =>
      _TransportationExamplePageState();
}

class _TransportationExamplePageState extends State<TransportationExamplePage> {
  final TransportationSensing sensing = TransportationSensing();

  StreamSubscription<Measurement>? _subscription;

  /// The most recently sampled measurements, newest first.
  final List<Measurement> _sampled = [];

  /// How many measurements of each data type have been sampled.
  final Map<String, int> _sampledByType = {};

  /// What is stored in SQLite, as read back by [_refreshStored].
  Map<String, int> _storedByType = {};

  bool _initialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await sensing.initialize();
    } catch (error) {
      // Never leave the UI on an endless spinner - show why sensing failed.
      if (mounted) setState(() => _error = error);
      return;
    }

    _subscription = sensing.measurements.listen((measurement) {
      setState(() {
        _sampled.insert(0, measurement);
        if (_sampled.length > 100) _sampled.removeLast();
        final type = measurement.dataType.name;
        _sampledByType[type] = (_sampledByType[type] ?? 0) + 1;
      });
    });

    setState(() => _initialized = true);
  }

  Future<void> _refreshStored() async {
    final stored = await sensing.countStoredMeasurementsByType();
    if (mounted) setState(() => _storedByType = stored);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    sensing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Transportation Example'),
        actions: [
          IconButton(
            tooltip: 'Read back what is stored in SQLite',
            onPressed: _initialized ? _refreshStored : null,
            icon: const Icon(Icons.storage),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not start sensing:\n\n$_error'),
              ),
            )
          : !_initialized
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _statusCard(),
                const SizedBox(height: 12),
                _countsCard(),
                const SizedBox(height: 12),
                _storedCard(),
                const SizedBox(height: 12),
                _logCard(),
              ],
            ),
    );

  /// What the study is doing and where its data goes.
  Widget _statusCard() => _card(
    title: 'Study',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          'Deployment',
          sensing.controller?.study.studyDeploymentId ?? 'not deployed',
        ),
        _row('Status', sensing.controller?.study.status.name ?? '-'),
        _row('Sampling', sensing.controller?.executor.state.name ?? '-'),
        _row('Data endpoint', 'SQLite'),
        _row('Database', sensing.databaseName ?? 'not open yet'),
        _row(
          'Batch',
          '${sensing.pipeline.buffered} / ${TransportationPipeline.batchSize} '
              'locations buffered',
        ),
        _row('Inferred', '${sensing.pipeline.numSamplesEmitted} samples'),
        const SizedBox(height: 8),
        Text(
          'The phone samples location continuously (distance filter 0). Every '
          '${TransportationPipeline.batchSize} locations, mode inference runs '
          'over the batch and emits one transportation sample per location. '
          'All of it is written to the local SQLite database.',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );

  /// What has been measured, per data type.
  Widget _countsCard() => _card(
    title: 'Measured (${_sampledByType.values.fold(0, (a, b) => a + b)})',
    child: _sampledByType.isEmpty
        ? const Text('Nothing sampled yet - run the pipeline.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _sampledByType.entries
                .map((entry) => _row(entry.key, '${entry.value}'))
                .toList(),
          ),
  );

  /// What is actually stored in SQLite, per data type.
  Widget _storedCard() => _card(
    title: 'Stored in SQLite (${_storedByType.values.fold(0, (a, b) => a + b)})',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_storedByType.isEmpty)
          const Text('Tap the storage icon to read back the database.')
        else
          ..._storedByType.entries.map(
            (entry) =>
                _row(entry.key.split('.').last, '${entry.value}'),
          ),
      ],
    ),
  );

  /// A live log of the measurements as they are sampled.
  Widget _logCard() => _card(
    title: 'Live measurements',
    child: _sampled.isEmpty
        ? const Text('No measurements yet.')
        : Column(
            children: _sampled
                .take(30)
                .map((measurement) => _measurementTile(measurement))
                .toList(),
          ),
  );

  /// One measurement, summarized - tap to see the JSON that is stored.
  Widget _measurementTile(Measurement measurement) {
    final data = measurement.data;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(_iconFor(data), size: 20),
      title: Text(
        measurement.dataType.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      subtitle: Text(_summarize(data), style: const TextStyle(fontSize: 12)),
      onTap: () => _showJson(measurement),
    );
  }

  /// A one-line, human readable summary of what was measured.
  String _summarize(Data data) => switch (data) {
    Location d =>
      '${d.latitude.toStringAsFixed(5)}, ${d.longitude.toStringAsFixed(5)}  '
          '${(d.speed ?? 0).toStringAsFixed(1)} m/s  '
          '±${(d.accuracy ?? 0).toStringAsFixed(0)} m',
    TransportationModelConfiguration d =>
      '${d.numModes} modes, model: ${d.embeddingModel}',
    StageConfiguration d => 'user: ${d.userId}, method: ${d.segmentMethod}',
    TransportationSample d =>
      '#${d.sampleId}  ${d.mode.name}  '
          '${d.latitude.toStringAsFixed(4)}, ${d.longitude.toStringAsFixed(4)}  '
          '${d.speed.toStringAsFixed(1)} m/s  '
          'confidence ${d.confidence.toStringAsFixed(2)}',
    MoveStage d =>
      'stage ${d.stageId}  ${d.mode.name}  '
          '${d.distance.toStringAsFixed(0)} m over ${d.numSamples} samples  '
          '${d.durationInMinutes.toStringAsFixed(1)} min',
    StopStage d =>
      'stage ${d.stageId}  '
          '${d.centroidLatitude.toStringAsFixed(4)}, '
          '${d.centroidLongitude.toStringAsFixed(4)}  '
          '${d.durationInMinutes.toStringAsFixed(1)} min',
    MobilityActivity d =>
      'activity ${d.activityId}  ${d.activityType.name}  '
          'at stop ${d.stopId}  ${d.dwellTime.toStringAsFixed(1)} min',
    StageModeCorrection d =>
      'stage ${d.stageId}  ${d.originalMode.name} -> ${d.correctedMode.name}',
    _ => data.toString(),
  };

  IconData _iconFor(Data data) => switch (data) {
    Location _ => Icons.my_location,
    TransportationSample _ => Icons.place_outlined,
    MoveStage _ => Icons.directions_bus,
    StopStage _ => Icons.pause_circle_outline,
    MobilityActivity _ => Icons.label_outline,
    StageModeCorrection _ => Icons.edit_outlined,
    _ => Icons.settings_outlined,
  };

  /// Show the exact JSON that the SQLite data manager stores.
  void _showJson(Measurement measurement) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          toJsonString(measurement),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    ),
  );

  Widget _card({required String title, required Widget child}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          child,
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
