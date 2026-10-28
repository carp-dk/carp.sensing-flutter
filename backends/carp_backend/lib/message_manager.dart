/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// A message (announcement, article or news) shown to participants in the app.
///
/// Messages are stored and fetched by a [MessageManager], such as
/// [CarpResourceManager].
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, explicitToJson: true)
class Message {
  /// ID of the message. A UUID is generated if none is given.
  late String id;

  /// Type of message.
  MessageType type;

  /// Creation time. Defaults to the time the message was created.
  late DateTime timestamp;

  /// A short title.
  String? title;

  /// A short sub title.
  String? subTitle;

  /// A longer detailed message.
  String? message;

  /// A URL to redirect the user to for an online item.
  String? url;

  /// The pathname for an image.
  ///
  /// This image path can have two forms:
  ///
  /// * URL - if the image path starts with http(s)://... the image is loaded
  ///         from the internet using the `Image.network()` constructor.
  /// * Asset - otherwise, it is assumed that this is the path to a local image
  ///           asset and the image is loaded from the asset bundle using the
  ///           `Image.asset()` constructor.
  String? image;

  /// Creates a message.
  ///
  /// If [id] is not specified, a UUID is assigned.
  /// If [timestamp] is not specified, the current time is used.
  Message({
    String? id,
    this.type = MessageType.announcement,
    this.title,
    this.subTitle,
    this.message,
    this.url,
    this.image,
    DateTime? timestamp,
  }) {
    this.id = id ?? const Uuid().v4();
    this.timestamp = timestamp ?? DateTime.now();
  }

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  String toString() => '$runtimeType - id: $id, type: $type, title: $title';
}

/// The type of a [Message].
enum MessageType { announcement, article, news }

/// Retrieves and stores [Message]s for a study.
///
/// Implemented by [CarpResourceManager], which keeps messages on CAWS.
abstract class MessageManager {
  /// Resets the manager, e.g. when the study changes.
  void initialize() {}

  /// The message with [messageId].
  ///
  /// Returns `null` if no message is found.
  Future<Message?> getMessage(String messageId);

  /// The messages from [start] to [end], at most [count] of them.
  ///
  /// If [start] is `null`, all messages back in time are included.
  /// If [end] is `null`, all messages up to now are included.
  ///
  /// The list is **not** sorted. Sorting, e.g. by date, is up to the app.
  Future<List<Message>> getMessages({DateTime? start, DateTime? end, int? count = 20});

  /// Stores [message], replacing any message with the same [Message.id].
  ///
  /// Messages are stored on CAWS using the [Message.id] as the document name.
  Future<void> setMessage(Message message);

  /// Deletes the message with [messageId] (the document name on CAWS).
  Future<void> deleteMessage(String messageId);

  /// Deletes all messages of the study.
  Future<void> deleteAllMessages();
}
