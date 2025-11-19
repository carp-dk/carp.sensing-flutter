/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// An online service which works as a "software device" in a protocol.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OnlineService<TRegistration extends DeviceRegistration>
    extends DeviceConfiguration<TRegistration> {
  OnlineService({required super.roleName, super.isOptional = true});
  @override
  Function get fromJsonFunction => _$OnlineServiceFromJson;

  factory OnlineService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OnlineService<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$OnlineServiceToJson(this);
}
