/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Says where and how the measurements of a study are stored or uploaded.
///
/// Set it as [SmartphoneStudyProtocol.dataEndPoint]. At runtime, the
/// [DataManagerRegistry] creates the [DataManager] whose
/// [DataManagerFactory.type] matches [type], and that data manager stores or
/// uploads each [Measurement].
///
/// Key points:
///  * [type] selects the data manager, see [DataEndPointTypes].
///  * [dataFormat] selects the [DataTransformerSchema] used to transform data
///    before it is stored, e.g. [NameSpace.OMH].
///  * Subclass it to add settings for your own data manager, e.g.
///    [FileDataEndPoint] or [SQLiteDataEndPoint].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DataEndPoint extends Serializable {
  /// The type of endpoint as enumerated in [DataEndPointTypes].
  String type;

  /// The preferred format of the data to be uploaded according to
  /// [NameSpace]. Default using the [NameSpace.CARP].
  String dataFormat;

  /// Creates a [DataEndPoint] of [type] (see [DataEndPointTypes]).
  ///
  /// [dataFormat] is a [NameSpace]. Default is [NameSpace.CARP].
  DataEndPoint({required this.type, this.dataFormat = NameSpace.CARP}) : super();

  @override
  Function get fromJsonFunction => _$DataEndPointFromJson;

  @override
  factory DataEndPoint.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<DataEndPoint>(json);

  @override
  Map<String, dynamic> toJson() => _$DataEndPointToJson(this);

  @override
  String toString() => '$runtimeType - type: $type, dataFormat: $dataFormat';
}

/// The known [DataEndPoint.type] values (not all are implemented).
///
/// The type is a [String], so you can add your own application-specific
/// data endpoints. CAMS implements [PRINT], [FILE], and [SQLITE]; the
/// carp_webservices package implements [CAWS].
class DataEndPointTypes {
  static const String UNKNOWN = 'UNKNOWN';

  /// Prints measurements to the console, see [ConsoleDataManager].
  static const String PRINT = 'PRINT';

  /// Stores measurements in JSON files, see [FileDataManager].
  static const String FILE = 'FILE';

  /// Stores measurements in a local SQLite database, see [SQLiteDataManager].
  static const String SQLITE = 'SQLITE';
  static const String FIREBASE_STORAGE = 'FIREBASE_STORAGE';
  static const String FIREBASE_DATABASE = 'FIREBASE_DATABASE';

  /// Uploads measurements to the CARP Web Services (CAWS) backend.
  static const String CAWS = 'CAWS';

  /// An Open mHealth endpoint.
  static const String OMH = 'OMH';
  static const String AWS = 'AWS';
}

/// A [DataEndPoint] that stores measurements as JSON files on the phone.
///
/// Used by the [FileDataManager]. Files can be zipped and encrypted.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FileDataEndPoint extends DataEndPoint {
  /// The buffer size of the raw JSON file in bytes.
  ///
  /// All collected data is written to a JSON file until the buffer is
  /// filled, at which time the file will be zipped. There is not a single-best
  /// [bufferSize] value.
  /// If data are collected at high rates, a higher value will be best to
  /// minimize zip operations. If data are collected at low rates, a lower
  /// value will be best to minimize the likelihood of data loss when the app
  /// is killed or crashes. Default size is 500 KB (500 * 1000 bytes).
  int bufferSize;

  /// Whether to compress (zip) the data before storing it in a file.
  /// Default is `true`.
  ///
  /// If zipped, the JSON file will be reduced to 1/5 of its size.
  /// For example, the 500 KB buffer typically is reduced to ~100 KB.
  bool zip = true;

  /// Whether to encrypt the data before storing it. Default is `false`.
  ///
  /// Support only one-way encryption using a public key.
  bool encrypt = false;

  /// The public key for RSA encryption of the data, used if [encrypt] is `true`.
  String? publicKey;

  /// Creates a [FileDataEndPoint] of type [DataEndPointTypes.FILE].
  FileDataEndPoint({
    super.dataFormat = NameSpace.CARP,
    this.bufferSize = 500 * 1000,
    this.zip = true,
    this.encrypt = false,
    this.publicKey,
  }) : super(type: DataEndPointTypes.FILE);

  @override
  Function get fromJsonFunction => _$FileDataEndPointFromJson;

  @override
  factory FileDataEndPoint.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<FileDataEndPoint>(json);

  @override
  Map<String, dynamic> toJson() => _$FileDataEndPointToJson(this);

  @override
  String toString() =>
      '$runtimeType - buffer ${(bufferSize / 1000).round()} KB'
      '${zip ? ', zipped' : ''}${encrypt ? ', encrypted' : ''}';
}

/// A [DataEndPoint] that stores measurements in a local SQLite database.
///
/// Used by the [SQLiteDataManager]. This is the default endpoint of
/// [SmartphoneStudyProtocol.local].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SQLiteDataEndPoint extends DataEndPoint {
  /// Creates a [SQLiteDataEndPoint] of type [DataEndPointTypes.SQLITE].
  SQLiteDataEndPoint({super.dataFormat = NameSpace.CARP}) : super(type: DataEndPointTypes.SQLITE);

  @override
  Function get fromJsonFunction => _$SQLiteDataEndPointFromJson;

  @override
  factory SQLiteDataEndPoint.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SQLiteDataEndPoint>(json);

  @override
  Map<String, dynamic> toJson() => _$SQLiteDataEndPointToJson(this);
}
