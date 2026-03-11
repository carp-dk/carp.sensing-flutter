/*
 * Copyright 2018 the Technical University of Denmark (DTU).
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
import 'dart:async';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show AppLifecycleState;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain/core/smartphone_protocol.dart';
part 'domain/core/study_description.dart';
part 'domain/core/data_endpoint.dart';
part 'domain/core/sampling_configurations.dart';
part 'domain/core/device_configurations.dart';
part 'domain/core/device_registrations.dart';
part 'domain/core/smartphone_study.dart';
part 'domain/core/smartphone_deployment.dart';
part 'domain/core/app_task.dart';
part 'domain/core/tasks.dart';
part 'domain/core/triggers.dart';
part 'domain/core/data.dart';
part 'domain/core/data_types.dart';
part 'domain/core/transformers.dart';
part 'infrastructure/services/device_info_service.dart';
part 'domain/services/data_manager.dart';
part 'domain/services/notification_manager.dart';
part 'domain/services/protocol_manager.dart';
part 'domain/services/sampling_package.dart';

part 'domain.g.dart';
