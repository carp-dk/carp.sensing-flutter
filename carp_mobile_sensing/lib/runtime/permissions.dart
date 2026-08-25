/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// Asks the user for [permissions] and completes once done.
///
/// Used to let an app take over how permissions are requested - e.g., to show
/// a rationale before each system dialog, or to defer them to an onboarding
/// flow. See [SmartPhoneClientManager.configure].
///
/// Whatever the user answers, CAMS re-checks the actual permission status
/// afterwards, so a requester never needs to report back.
typedef PermissionRequester =
    Future<void> Function(List<Permission> permissions);

/// Requests [permissions] one at a time, skipping those already granted.
///
/// This is the default [PermissionRequester].
///
/// One at a time is not a style choice: `permission_handler` forbids concurrent
/// requests, and a permission that unlocks another one can only be granted if
/// asked first.
Future<void> requestPermissionsInOrder(List<Permission> permissions) async {
  final asked = <Permission>{};

  for (final permission in permissions.expand(_withPrerequisite)) {
    if (!asked.add(permission)) continue;
    if (await permission.isGranted) continue;

    final name = permission.toString().split('.').last;
    final asking = DateTime.now();
    final status = await permission.request();
    final took = DateTime.now().difference(asking);

    // The duration is the tell: a dialog the participant actually saw takes
    // hundreds of ms at least. An instant answer means Android refused to show
    // one - "Can request only one set of permissions at a time" - because
    // something else was already asking.
    info('Permission $name: ${status.name} (${took.inMilliseconds}ms)');
    if (took.inMilliseconds < 50 && status.isDenied) {
      warning('Permission $name was denied without a dialog - another request '
          'was already in progress.');
    }
  }
}

/// Android only offers `locationAlways` once `locationWhenInUse` is granted,
/// and only in a separate dialog. Climbing that ladder here means a study can
/// declare the permissions it needs in any order and still get asked correctly.
Iterable<Permission> _withPrerequisite(Permission permission) =>
    permission == Permission.locationAlways
    ? [Permission.locationWhenInUse, permission]
    : [permission];
