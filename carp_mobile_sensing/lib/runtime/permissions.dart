/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// Asks the user for [permissions] and completes once done.
///
/// Lets an app take over how permissions are requested - e.g., to show a
/// rationale before each system dialog. See [SmartPhoneClientManager.configure].
///
/// Whatever the user answers, CAMS re-checks the actual permission status
/// afterwards, so a requester never needs to report back.
///
/// A requester runs *inside* the permission queue, so it must call
/// `permission_handler` directly and never
/// [SmartPhoneClientManager.requestPermissions] - that would wait on itself.
typedef PermissionRequester =
    Future<void> Function(List<Permission> permissions);

/// Requests [permissions] one at a time, skipping those already granted.
///
/// This is the default [PermissionRequester].
///
/// One at a time is not a style choice: Android denies - without showing a
/// dialog - any request made while another one is up, and a permission that
/// unlocks another one can only be granted if asked first.
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
    // hundreds of ms at least. An instant denial means Android refused to
    // show one because something else was already asking.
    info('Permission $name: ${status.name} (${took.inMilliseconds}ms)');
    if (took.inMilliseconds < 50 && status.isDenied) {
      warning(
        'Permission $name was denied without a dialog - another request '
        'was already in progress.',
      );
    }
  }
}

/// Android only offers `locationAlways` once `locationWhenInUse` is granted,
/// and only in a separate dialog. Climbing that ladder here means callers can
/// declare the permissions they need in any order and still get asked correctly.
Iterable<Permission> _withPrerequisite(Permission permission) =>
    permission == Permission.locationAlways
    ? [Permission.locationWhenInUse, permission]
    : [permission];
