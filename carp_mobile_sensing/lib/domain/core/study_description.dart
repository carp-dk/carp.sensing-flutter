/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A human-readable description of a study: title, purpose, and who runs it.
///
/// Stored as [SmartphoneStudyProtocol.studyDescription] and copied to each
/// [SmartphoneDeployment], so the app can show it to the participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StudyDescription extends Serializable {
  /// A longer printer-friendly title for this study.
  String title;

  /// The description of this study.
  String? description;

  /// The purpose of the study. To be used to inform the user about
  /// this study and its purpose.
  String? purpose;

  /// The URL pointing to a web page description of this study.
  String? studyDescriptionUrl;

  /// The URL pointing to a web page with the privacy policy of this study.
  String? privacyPolicyUrl;

  /// The principal investigator (PI) responsible for this study.
  StudyResponsible? responsible;

  StudyDescription({
    required this.title,
    this.description,
    this.purpose,
    this.studyDescriptionUrl,
    this.privacyPolicyUrl,
    this.responsible,
  });

  @override
  Function get fromJsonFunction => _$StudyDescriptionFromJson;
  factory StudyDescription.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StudyDescription>(json);
  @override
  Map<String, dynamic> toJson() => _$StudyDescriptionToJson(this);

  @override
  String toString() =>
      '$runtimeType -  title: $title, description: $description. purpose: $purpose';
}

/// A person who is responsible for a [StudyProtocol].
/// Typically the Principal Investigator (PI) who is responsible for the study.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StudyResponsible extends Serializable {
  /// A unique id of this person.
  String id;
  String name;

  /// The job title, e.g. "Professor".
  String? title;
  String? email;
  String? address;

  /// The institution this person belongs to.
  String? affiliation;

  StudyResponsible({
    required this.id,
    required this.name,
    this.title,
    this.email,
    this.affiliation,
    this.address,
  });

  @override
  Function get fromJsonFunction => _$StudyResponsibleFromJson;
  factory StudyResponsible.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StudyResponsible>(json);
  @override
  Map<String, dynamic> toJson() => _$StudyResponsibleToJson(this);

  @override
  String toString() => '$runtimeType - $name, $title <$email>';
}
