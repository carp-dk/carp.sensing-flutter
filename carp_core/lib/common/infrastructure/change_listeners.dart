part of '../../common.dart';

/// Callbacks to call when an object changes.
/// Same methods as Flutter's `ChangeNotifier`, so `carp_core` stays pure Dart.
mixin ChangeListeners {
  final _listeners = <void Function()>[];

  /// Call [listener] every time this object changes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Stop calling [listener].
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Is anyone listening?
  bool get hasListeners => _listeners.isNotEmpty;

  /// Remove all listeners.
  void dispose() => _listeners.clear();

  /// Call all listeners. A listener that throws does not stop the others,
  /// and a listener removed by another one is not called.
  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      if (!_listeners.contains(listener)) continue;
      try {
        listener();
      } catch (error, stack) {
        print('$runtimeType - a listener failed: $error\n$stack');
      }
    }
  }
}
