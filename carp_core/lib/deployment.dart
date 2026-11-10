/// Deployments: turning a study protocol into what runs on each device.
///
/// A [StudyDeployment] maps a [StudyProtocol] to runtime configurations
/// ([PrimaryDeviceDeployment]) used by the client subsystem, and lets
/// researchers monitor its state ([StudyDeploymentStatus]).
/// To start collecting data, participants are invited, devices are
/// registered, and participant data (e.g., consent) is collected.
///
/// Main types: [DeploymentService], [ParticipationService], [StudyDeployment],
/// [StudyDeploymentStatus], [PrimaryDeviceDeployment] and [ParticipantData].
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
