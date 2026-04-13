/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// All supported input data types.
abstract class InputType {
  static const INPUT_TYPE_NAMESPACE = '${NameSpace.CARP}.input';
  static const CAWS_INPUT_TYPE_NAMESPACE = 'dk.carp.webservices.input';
  static const CUSTOM = '${InputType.INPUT_TYPE_NAMESPACE}.custom';
  static const SEX = '${InputType.INPUT_TYPE_NAMESPACE}.sex';
  static const PHONE_NUMBER =
      '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.phone_number';
  static const SSN = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.ssn';
  static const FULL_NAME = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.full_name';
  static const INFORMED_CONSENT =
      '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.informed_consent';
  static const ADDRESS = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.address';
  static const DIAGNOSIS = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.diagnosis';

  static const NOTE = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.note';
  static const EDUCATIONAL_DEGREE =
      '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.educational_degree';
  static const ONBOARDING_RESEARCHER =
      '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.onboarding_researcher';
  static const LANGUAGE = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.language';
  static const OCCUPATION = '${InputType.CAWS_INPUT_TYPE_NAMESPACE}.occupation';
}

/// Base class for all input data types.
abstract class InputData extends Data {
  /// The type of this input data.
  String get type;

  @override
  String get jsonType => type;
}

/// Custom input data as requested by a researcher.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CustomInput extends InputData {
  @override
  String get type => InputType.CUSTOM;

  /// Any serializable value.
  dynamic value;

  CustomInput({this.value}) : super();

  @override
  Function get fromJsonFunction => _$CustomInputFromJson;
  factory CustomInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CustomInput>(json);
  @override
  Map<String, dynamic> toJson() => _$CustomInputToJson(this);
}

/// Biological sex of a person.
enum Sex { Male, Female, Intersex }

/// The biological sex assigned at birth of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SexInput extends InputData {
  @override
  String get type => InputType.SEX;

  /// Biological sex of a participant.
  Sex value;

  SexInput({required this.value}) : super();

  @override
  Function get fromJsonFunction => _$SexInputFromJson;
  factory SexInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SexInput>(json);
  @override
  Map<String, dynamic> toJson() => _$SexInputToJson(this);
}

/// The phone number of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PhoneNumberInput extends InputData {
  @override
  String get type => InputType.PHONE_NUMBER;

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
}

/// The social security number (SSN) of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SocialSecurityNumberInput extends InputData {
  @override
  String get type => InputType.SSN;

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
}

/// The full name of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FullNameInput extends InputData {
  @override
  String get type => InputType.FULL_NAME;

  String? firstName, middleName, lastName;

  FullNameInput({this.firstName, this.middleName, this.lastName}) : super();

  @override
  Function get fromJsonFunction => _$FullNameInputFromJson;
  factory FullNameInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FullNameInput>(json);
  @override
  Map<String, dynamic> toJson() => _$FullNameInputToJson(this);
}

/// The informed consent from a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InformedConsentInput extends InputData {
  @override
  String get type => InputType.INFORMED_CONSENT;

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
}

/// The full address of a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AddressInput extends InputData {
  @override
  String get type => InputType.ADDRESS;

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
}

/// The diagnosis of a patient.
///
/// We are using the WHO [ICD-11](https://www.who.int/standards/classifications/classification-of-diseases)
/// classification.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DiagnosisInput extends InputData {
  @override
  String get type => InputType.DIAGNOSIS;

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
}

/// A general note about the participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class NoteInput extends InputData {
  @override
  String get type => InputType.NOTE;

  /// Free-text note tied to the participant.
  String note;

  NoteInput({required this.note}) : super();

  @override
  Function get fromJsonFunction => _$NoteInputFromJson;
  factory NoteInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<NoteInput>(json);
  @override
  Map<String, dynamic> toJson() => _$NoteInputToJson(this);
}

/// Highest completed educational degree, mapped to the [ISCED](https://www.uis.unesco.org/en/methods-and-tools/isced)
/// framework for cross-country comparability.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EducationalDegreeInput extends InputData {
  @override
  String get type => InputType.EDUCATIONAL_DEGREE;

  /// The ISCED level of the completed degree.
  IscedLevel level;

  /// Optional free-text details (e.g., subject, institution).
  String? details;

  EducationalDegreeInput({required this.level, this.details}) : super();

  @override
  Function get fromJsonFunction => _$EducationalDegreeInputFromJson;
  factory EducationalDegreeInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<EducationalDegreeInput>(json);
  @override
  Map<String, dynamic> toJson() => _$EducationalDegreeInputToJson(this);
}

/// The [ISCED](https://www.uis.unesco.org/en/methods-and-tools/isced)
/// framework education levels.
enum IscedLevel {
  /// No formal education
  ISCED_0,

  /// Primary education
  ISCED_1,

  /// Lower secondary education
  ISCED_2,

  /// Upper secondary education
  ISCED_3,

  /// Post-secondary non-tertiary education
  ISCED_4,

  /// Short-cycle tertiary education
  ISCED_5,

  /// Bachelor or equivalent
  ISCED_6,

  /// Master or equivalent
  ISCED_7,

  /// Doctoral or equivalent
  ISCED_8,
}

/// Information about the researcher who onboarded the participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OnboardingResearcherInput extends InputData {
  @override
  String get type => InputType.ONBOARDING_RESEARCHER;

  /// Identifier for the onboarding researcher.
  String researcherId;

  /// Full name of the onboarding researcher.
  String researcherName;

  /// The name of the institution of the onboarding researcher (optional).
  String? institutionName;

  OnboardingResearcherInput({
    required this.researcherId,
    required this.researcherName,
    this.institutionName,
  }) : super();

  @override
  Function get fromJsonFunction => _$OnboardingResearcherInputFromJson;
  factory OnboardingResearcherInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OnboardingResearcherInput>(json);
  @override
  Map<String, dynamic> toJson() => _$OnboardingResearcherInputToJson(this);
}

/// Preferred language of the participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PreferredLanguageInput extends InputData {
  @override
  String get type => InputType.LANGUAGE;

  /// ISO 639-1 or 639-3 code (e.g., "en", "da").
  String languageCode;

  /// Optional locale/region qualifier (e.g., "US", "DK").
  String? region;

  /// Human-readable language name, if needed.
  String? displayName;

  PreferredLanguageInput({
    required this.languageCode,
    this.region,
    this.displayName,
  }) : super();

  @override
  Function get fromJsonFunction => _$PreferredLanguageInputFromJson;
  factory PreferredLanguageInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PreferredLanguageInput>(json);
  @override
  Map<String, dynamic> toJson() => _$PreferredLanguageInputToJson(this);
}

/// Occupation details of a participant (supports multiple selections).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OccupationInput extends InputData {
  @override
  String get type => InputType.OCCUPATION;

  /// ISO 639-1 or 639-3 code (e.g., "en", "da").
  List<String> roles = [];

  /// Free-text occupation if none of the predefined roles fit.
  String? other;

  OccupationInput({List<String>? roles, this.other}) : super() {
    this.roles = roles ?? [];
  }

  @override
  Function get fromJsonFunction => _$OccupationInputFromJson;
  factory OccupationInput.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OccupationInput>(json);
  @override
  Map<String, dynamic> toJson() => _$OccupationInputToJson(this);
}
