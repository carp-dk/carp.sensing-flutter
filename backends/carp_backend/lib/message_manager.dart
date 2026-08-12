/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// A message to be shown in the message list
@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class Message {
  /// ID of the message.
  late String id;

  /// Type of message.
  MessageType type;

  /// Creation timestamp.
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

  /// Create a new message.
  ///
  /// If [id] is not specified, a UUID will be assigned.
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

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  String toString() => '$runtimeType - id: $id, type: $type, title: $title';
}

/// The different types of messages that can occur in the list of messages
enum MessageType {
  announcement,
  article,
  news,
}

abstract class MessageManager {
  /// Initialize the [MessageManager].
  void initialize() {}

  /// Get a message based on its id.
  ///
  /// Returns null if no message is found.
  Future<Message?> getMessage(String messageId);

  /// Get a list of messages in a given time period from [start] to [end]
  /// with a maximum of [count] messages.
  ///
  /// If [start] is null, all messages back in time is included.
  /// If [end] is null, all messages up to now is included.
  ///
  /// Note that the list is **not** sorted in any way.
  /// Sorting - e.g., by date - must be handled by the app if needed.
  Future<List<Message>> getMessages({
    DateTime? start,
    DateTime? end,
    int? count = 20,
  });

  /// Set a message.
  ///
  /// Messages are stored on CARP using the [Message.id] as the document name.
  Future<void> setMessage(Message message);

  /// Delete a message based on its id (i.e., document name on CARP).
  Future<void> deleteMessage(String messageId);

  /// Deletes all messages.
  Future<void> deleteAllMessages();
}
