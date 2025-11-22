/*
 * Copyright 2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Uniquely identifies an account and its associated identity.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Account {
  /// Identity associated with this account.
  AccountIdentity identity;
  late String id;

  Account({String? id, required this.identity}) {
    this.id = id ?? const Uuid().v1;
  }

  /// Create a new [Account] uniquely identified by the specified [emailAddress].
  Account.withEmailIdentity(String emailAddress)
    : this(identity: EmailAccountIdentity(emailAddress));

  /// Create a new [Account] uniquely identified by the specified [username].
  Account.withUsernameIdentity(String username)
    : this(identity: UsernameAccountIdentity(username));

  /// Determines whether this account has the same [identity] as [otherAccount].
  bool hasSameIdentity(Account otherAccount) =>
      identity == otherAccount.identity;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

/// Identifies an [Account].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccountIdentity extends Serializable {
  AccountIdentity() : super();

  @override
  String get jsonType => 'dk.cachet.carp.common.application.users.$runtimeType';
  @override
  Function get fromJsonFunction => _$AccountIdentityFromJson;
  factory AccountIdentity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AccountIdentity>(json);
  @override
  Map<String, dynamic> toJson() => _$AccountIdentityToJson(this);
}

/// Identifies an  account by a unique [emailAddress].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EmailAccountIdentity extends AccountIdentity {
  String emailAddress;
  EmailAccountIdentity(this.emailAddress);

  @override
  Function get fromJsonFunction => _$EmailAccountIdentityFromJson;
  factory EmailAccountIdentity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<EmailAccountIdentity>(json);
  @override
  Map<String, dynamic> toJson() => _$EmailAccountIdentityToJson(this);

  @override
  String toString() => '$runtimeType - emailAddress: $emailAddress';
}

/// Identifies an account by a unique [username].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UsernameAccountIdentity extends AccountIdentity {
  String username;
  UsernameAccountIdentity(this.username);

  @override
  Function get fromJsonFunction => _$UsernameAccountIdentityFromJson;
  factory UsernameAccountIdentity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<UsernameAccountIdentity>(json);
  @override
  Map<String, dynamic> toJson() => _$UsernameAccountIdentityToJson(this);

  @override
  String toString() => '$runtimeType - username: $username';
}
