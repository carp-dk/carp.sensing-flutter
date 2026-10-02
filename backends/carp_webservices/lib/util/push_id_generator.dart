// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../carp_services/carp_services.dart';

/// Utility class for generating CARP document keys.
///
/// This code is taken from the Flutter `cloud_firestore` package supporting Firebase.
/// This code is based on a Firebase blog post and ported to Dart.
/// https://firebase.googleblog.com/2015/02/the-2120-ways-to-ensure-unique_68.html
class PushIdGenerator {
  /// The 64 characters used in generated keys, in sort order.
  static const String PUSH_CHARS =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';

  static final Random _random = Random();

  static int _lastPushTime = 0;

  static final List<int> _lastRandChars = List.filled(12, 0);

  /// Generates a unique 20-character key.
  ///
  /// The first 8 characters encode the current time, so keys sort by
  /// creation time. Used by [CollectionReference.document] when no name is
  /// given.
  static String generatePushChildName() {
    int now = DateTime.now().millisecondsSinceEpoch;
    final bool duplicateTime = (now == _lastPushTime);
    _lastPushTime = now;

    final List<String> timeStampChars = List.filled(8, '');
    for (int i = 7; i >= 0; i--) {
      timeStampChars[i] = PUSH_CHARS[now % 64];
      now = (now / 64).floor();
    }
    assert(now == 0);

    final StringBuffer result = StringBuffer(timeStampChars.join());

    if (!duplicateTime) {
      for (int i = 0; i < 12; i++) {
        _lastRandChars[i] = _random.nextInt(64);
      }
    } else {
      _incrementArray();
    }
    for (int i = 0; i < 12; i++) {
      result.write(PUSH_CHARS[_lastRandChars[i]]);
    }
    assert(result.length == 20);
    return result.toString();
  }

  static void _incrementArray() {
    for (int i = 11; i >= 0; i--) {
      if (_lastRandChars[i] != 63) {
        _lastRandChars[i] = _lastRandChars[i] + 1;
        return;
      }
      _lastRandChars[i] = 0;
    }
  }
}
