import 'dart:async';
import 'dart:io';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trigger_example.g.dart';

/// A trigger that triggers based on event from a remote server.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RemoteTrigger extends TriggerConfiguration {
  RemoteTrigger({
    required this.uri,
    this.interval = const Duration(minutes: 10),
  }) : super();

  /// The URI of the resource to listen to.
  String uri;

  /// How often should we check the server?
  Duration interval;

  @override
  Function get fromJsonFunction => _$RemoteTriggerFromJson;
  factory RemoteTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RemoteTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$RemoteTriggerToJson(this);
}

/// Executes a [RemoteTrigger], i.e. check if there is a resource on
/// the server and triggers if so.
class RemoteTriggerExecutor extends TriggerExecutor<RemoteTrigger> {
  final client = Client();

  @override
  Future<bool> onResume() async {
    // Set up a periodic timer to look for a resource at the specified URI
    timer = Timer.periodic(configuration!.interval, (_) async {
      var response = await client.get(
        Uri.parse(Uri.encodeFull(configuration!.uri)),
      );

      if (response.statusCode == HttpStatus.ok) {
        // If there is a resource at the specified URI, then trigger this executor
        onTrigger();
      }
    });
    return true;
  }
}

/// A [TriggerFactory] for remote triggers.
class RemoteTriggerFactory implements TriggerFactory {
  @override
  Set<Type> types = {
    // Note that this factory might support several types of remote triggers
    RemoteTrigger,
  };

  @override
  void onRegister() {
    // When registering this factory add the triggers to the JSON serialization
    FromJsonFactory().registerAll([RemoteTrigger(uri: 'uri')]);
  }

  @override
  TriggerExecutor<TriggerConfiguration> create(TriggerConfiguration trigger) =>
      switch (trigger) {
        RemoteTrigger _ => RemoteTriggerExecutor(),
        _ => ImmediateTriggerExecutor(),
      };
}

class Sensing {
  void init() {
    // create and register external sampling packages
    // SamplingPackageRegistry().register(ContextSamplingPackage());
    // SamplingPackageRegistry().register(MediaSamplingPackage());
    // SamplingPackageRegistry().register(SurveySamplingPackage());
    // SamplingPackageRegistry().register(HealthSamplingPackage());
    // SamplingPackageRegistry().register(ESenseSamplingPackage());
    // SamplingPackageRegistry().register(PolarSamplingPackage());
    // SamplingPackageRegistry().register(MovesenseSamplingPackage());

    // create and register external data managers
    // DataManagerRegistry().register(CarpDataManagerFactory());

    // register the special-purpose audio user task factory
    // AppTaskController().registerUserTaskFactory(AppUserTaskFactory());

    // register special-purpose trigger factory
    ExecutorFactory().registerTriggerFactory(RemoteTriggerFactory());
  }
}
