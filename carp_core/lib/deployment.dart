/// Maps the information specified in a study protocol to runtime configurations
/// used by the 'clients' subsystem to run the protocol on concrete devices
/// (e.g., a smartphone) and allow researchers to monitor their state.
/// To start collecting data, participants need to be invited, devices need to
/// be registered, and consent needs to be given to collect the requested data.
///
/// Contains the core deployment classes like [PrimaryDeviceDeployment], [StudyDeployment],
/// [ParticipantData], and [DeploymentService].
///
/// See the [`carp.deployments`](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-deployments.md)
/// definition in Kotlin.
library;

import 'package:flutter/material.dart' show ChangeNotifier;

import 'package:carp_core/carp_core.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';

part 'deployment/application/deployment_service.dart';
part 'deployment/application/participation_service.dart';
part 'deployment/application/device_deployment.dart';
part 'deployment/domain/study_deployment.dart';
part 'deployment/domain/participation.dart';
part 'deployment/application/users.dart';
part 'deployment/infrastructure/deployment_requests.dart';
part 'deployment/infrastructure/participation_requests.dart';

part 'deployment.g.dart';
