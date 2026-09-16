import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // The following adds notification support from flutter_local_notifications
    // See example app - https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/ios/Runner/AppDelegate.swift
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // With the UIScene life cycle the implicit FlutterEngine is created by the
  // FlutterViewController in Main.storyboard - i.e. after the app delegate has
  // finished launching - so plugins are registered here rather than in
  // `application(_:didFinishLaunchingWithOptions:)`.
  // See https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
