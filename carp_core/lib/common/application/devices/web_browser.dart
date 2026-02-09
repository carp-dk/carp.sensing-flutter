/*
 * Copyright 2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Configuration of an internet-connected web browser device with no built-in [sensors].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WebBrowser extends PrimaryDeviceConfiguration<WebBrowserRegistration> {
  /// The type of a web browser device device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.WebBrowser';

  /// The default role name for a web browser device.
  static const String DEFAULT_ROLE_NAME = 'Primary Web Browser';

  /// Create a new web browser device descriptor.
  /// If [roleName] is not specified, then the [DEFAULT_ROLE_NAME] is used.
  WebBrowser({super.roleName = WebBrowser.DEFAULT_ROLE_NAME});

  @override
  WebBrowserRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
    String? browserName,
    int? deviceMemory,
    String? language,
    String? vendor,
    int? maxTouchPoints,
    int? hardwareConcurrency,
  }) => WebBrowserRegistration(
    deviceId: deviceId,
    deviceDisplayName: deviceDisplayName,
    browserName: browserName,
    deviceMemory: deviceMemory,
    language: language,
    vendor: vendor,
    maxTouchPoints: maxTouchPoints,
    hardwareConcurrency: hardwareConcurrency,
  );

  @override
  Function get fromJsonFunction => _$WebBrowserFromJson;
  factory WebBrowser.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<WebBrowser>(json);
  @override
  Map<String, dynamic> toJson() => _$WebBrowserToJson(this);
}

/// A [DeviceRegistration] for a [WebBrowser] specifying details of the browser.
///
/// Takes inspiration from the device information available via the
/// [device_info_plus](https://pub.dev/packages/device_info_plus) via the
/// [WebBrowserInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/WebBrowserInfo-class.html) class.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WebBrowserRegistration extends DeviceRegistration {
  String? browserName;
  int? deviceMemory;
  String? language;
  String? vendor;
  int? maxTouchPoints;
  int? hardwareConcurrency;

  WebBrowserRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    this.browserName,
    this.deviceMemory,
    this.language,
    this.vendor,
    this.maxTouchPoints,
    this.hardwareConcurrency,
  });

  @override
  Function get fromJsonFunction => _$WebBrowserRegistrationFromJson;
  factory WebBrowserRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<WebBrowserRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$WebBrowserRegistrationToJson(this);
}
