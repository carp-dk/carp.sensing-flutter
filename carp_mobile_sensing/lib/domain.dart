/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// This library hold the CAMS-specific extensions and implementation of the
/// [carp_core](https://pub.dev/packages/carp_core) domain classes like
/// [SmartphoneStudyProtocol] and [PeriodicTrigger].
///
/// Also hold JSON logic to handle de/serialization of the domain objects.
///
/// In terms of Domain-Driven Design (DDD), "the domain layer is responsible for
/// implementing the core business logic and rules of the system. It contains
/// the domain model, which is a representation of the concepts and behaviors
/// that are relevant to the problem domain. The domain model consists of entities,
/// value objects, aggregates, services, events, and other elements that capture
/// the essence and meaning of the domain."
/// From [Domain-Driven Design (DDD): A Guide to Building Scalable, High-Performance Systems](https://romanglushach.medium.com/domain-driven-design-ddd-a-guide-to-building-scalable-high-performance-systems-5314a7fe053c) by Roman Glushach.
library;

import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:carp_core/carp_core.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:permission_handler/permission_handler.dart';

part 'domain/study_protocol.dart';
part 'domain/study_description.dart';
part 'domain/data_endpoint.dart';
part 'domain/sampling_configurations.dart';
part 'domain/device_configurations.dart';
part 'domain/smartphone_study.dart';
part 'domain/smartphone_deployment.dart';
part 'domain/app_task.dart';
part 'domain/tasks.dart';
part 'domain/triggers.dart';
part 'domain/data.dart';
part 'domain/data_types.dart';
part 'domain/device_info.dart';
part 'domain/transformers.dart';

part 'domain.g.dart';
