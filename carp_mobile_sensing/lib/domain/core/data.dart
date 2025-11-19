/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A [Data] object holding a link to a file.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FileData extends Data {
  static const dataType = CamsDataTypes.FILE_TYPE_NAME;

  /// The local path to the attached file on the phone where it is sampled.
  /// This is used by e.g. a data manager to get and manage the file on
  /// the phone.
  // @JsonKey(includeFromJson: false, includeToJson: false)
  String? path;

  /// The name to the attached file.
  String filename;

  /// Should the file also be uploaded, or only this meta data?
  /// Default is true.
  bool upload = true;

  /// Metadata for this file as a map of string key-value pairs.
  Map<String, String>? metadata = <String, String>{};

  /// Create a new [FileData] based the file path and whether it is
  /// to be uploaded or not.
  FileData({required this.filename, this.upload = true}) : super();

  @override
  bool equivalentTo(Data other) =>
      other is FileData && filename == other.filename;

  @override
  Function get fromJsonFunction => _$FileDataFromJson;
  factory FileData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FileData>(json);
  @override
  Map<String, dynamic> toJson() => _$FileDataToJson(this);
}
