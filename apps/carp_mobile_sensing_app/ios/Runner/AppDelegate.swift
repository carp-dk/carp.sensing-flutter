import Flutter
import UIKit
import flutter_local_notifications

// import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // The following adds notification support.
    //
    // Note that CAMS have implementation for BOTH flutter_local_notifications
    // and awesome_notifications. BUT you can ONLY use one or the other.
    // Which notification controller to use, is specified in the SmartPhoneClientManager.configure()
    // methods.
    //
    // Depending on which notification controller you want to use, include one or the other of
    // the following swift code.

    // From flutter_local_notifications
    // See example app - https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/ios/Runner/AppDelegate.swift
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // From awesome_notifications -- see https://pub.dev/packages/awesome_notifications#-extra-ios-setup-for-background-actions
    // See example app - https://github.com/rafaelsetragni/awesome_notifications/blob/master/example/ios/Runner/AppDelegate.swift
    // This function registers the desired plugins to be used within a notification background action
    // SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
    //     SwiftAwesomeNotificationsPlugin.register(
    //       with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
    // }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
