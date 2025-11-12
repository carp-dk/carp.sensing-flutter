/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_core_common.dart';

/// Custom input data as requested by a researcher.
abstract class InputType {
  static const INPUT_TYPE_NAMESPACE = '${NameSpace.CARP}.input';
  static const CAWS_INPUT_TYPE_NAMESPACE = 'dk.carp.webservices.input';
}

/// Custom input data as requested by a researcher.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CustomInput extends Data {
  static const type = '${InputType.INPUT_TYPE_NAMESPACE}.custom';

  /// Any serializable value.
  dynamic value;

  CustomInput({this.value}) : super();

  @override
  Function get fromJsonFunction => _$CustomInputFromJson;
  factory CustomInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CustomInput>(json);
  @override
  Map<String, dynamic> toJson() => _$CustomInputToJson(this);
  @override
  String get jsonType => type;
}

/// Biological sex of a person.
enum Sex { Male, Female, Intersex }

/// The biological sex assigned at birth of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SexInput extends Data {
  static const type = '${InputType.INPUT_TYPE_NAMESPACE}.sex';

  /// Biological sex of a participant.
  Sex value;

  SexInput({required this.value}) : super();

  @override
  Function get fromJsonFunction => _$SexInputFromJson;
  factory SexInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SexInput>(json);
  @override
  Map<String, dynamic> toJson() => _$SexInputToJson(this);
  @override
  String get jsonType => type;
}

/// The phone number of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PhoneNumberInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.phone_number';

  /// The country code of this phone number.
  ///
  /// The country code is represented by a string, since some country codes
  /// contain a '-'. For example, "1-246" for Barbados or "44-1481" for Guernsey.
  ///
  /// See https://countrycode.org/ or https://en.wikipedia.org/wiki/List_of_country_calling_codes
  String countryCode;

  /// The ISO 3166 code of the [countryCode], if available.
  ///
  /// See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
  String? isoCode;

  /// The phone number.
  ///
  /// The phone number is represented as a string since it may be pretty-printed
  /// with spaces.
  String number;

  PhoneNumberInput({required this.countryCode, required this.number}) : super();

  @override
  Function get fromJsonFunction => _$PhoneNumberInputFromJson;
  factory PhoneNumberInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PhoneNumberInput>(json);
  @override
  Map<String, dynamic> toJson() => _$PhoneNumberInputToJson(this);
  @override
  String get jsonType => type;
}

/// The social security number (SSN) of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SocialSecurityNumberInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.ssn';

  /// The social security number (SSN)
  String socialSecurityNumber;

  /// The country in which this [socialSecurityNumber] originates from.
  String country;

  SocialSecurityNumberInput({
    required this.socialSecurityNumber,
    required this.country,
  }) : super();

  @override
  Function get fromJsonFunction => _$SocialSecurityNumberInputFromJson;
  factory SocialSecurityNumberInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SocialSecurityNumberInput>(json);
  @override
  Map<String, dynamic> toJson() => _$SocialSecurityNumberInputToJson(this);
  @override
  String get jsonType => type;
}

/// The full name of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FullNameInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.full_name';

  String? firstName, middleName, lastName;

  FullNameInput({this.firstName, this.middleName, this.lastName}) : super();

  @override
  Function get fromJsonFunction => _$FullNameInputFromJson;
  factory FullNameInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FullNameInput>(json);
  @override
  Map<String, dynamic> toJson() => _$FullNameInputToJson(this);
  @override
  String get jsonType => type;
}

/// The informed consent from a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InformedConsentInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.informed_consent';

  /// The time this informed consent was signed.
  late DateTime signedTimestamp;

  /// The location where this informed consent was signed.
  String? signedLocation;

  /// The ID of the participant who signed this consent.
  String userId;

  /// The full name of the participant who signed this consent.
  String name;

  /// The content of the signed consent.
  ///
  /// This may be plain text or JSON.
  String consent;

  /// The image of the provided signature in png format as bytes.
  String signatureImage;

  InformedConsentInput({
    DateTime? signedTimestamp,
    this.signedLocation,
    required this.userId,
    required this.name,
    required this.consent,
    required this.signatureImage,
  }) : super() {
    this.signedTimestamp = (signedTimestamp ?? DateTime.now()).toUtc();
  }

  @override
  Function get fromJsonFunction => _$InformedConsentInputFromJson;
  factory InformedConsentInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<InformedConsentInput>(json);
  @override
  Map<String, dynamic> toJson() => _$InformedConsentInputToJson(this);
  @override
  String get jsonType => type;
}

/// The full address of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AddressInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.address';

  String? address1, address2, street, city, postalCode, country;
  AddressInput({
    this.address1,
    this.address2,
    this.street,
    this.city,
    this.postalCode,
    this.country,
  }) : super();

  @override
  Function get fromJsonFunction => _$AddressInputFromJson;
  factory AddressInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AddressInput>(json);
  @override
  Map<String, dynamic> toJson() => _$AddressInputToJson(this);
  @override
  String get jsonType => type;
}

/// The diagnosis of a patient.
///
/// We are using the WHO [ICD-11](https://www.who.int/standards/classifications/classification-of-diseases)
/// classification.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DiagnosisInput extends Data {
  static const type = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.diagnosis';

  /// The date this diagnosis was effective.
  DateTime? effectiveDate;

  /// A free text description of the diagnosis.
  String? diagnosis;

  /// The [ICD-11](https://www.who.int/standards/classifications/classification-of-diseases)
  /// code of this diagnosis.
  String icd11Code;

  /// Any conclusion or notes from the physician.
  String? conclusion;

  DiagnosisInput({
    this.effectiveDate,
    this.diagnosis,
    required this.icd11Code,
    this.conclusion,
  }) : super();

  @override
  Function get fromJsonFunction => _$DiagnosisInputFromJson;
  factory DiagnosisInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DiagnosisInput>(json);
  @override
  Map<String, dynamic> toJson() => _$DiagnosisInputToJson(this);
  @override
  String get jsonType => type;
}
