//
//  CarpWatchSensorController.swift
//  Runner
//
//  Created by Alireza Hajebrahimi on 18/08/2026.
//

import Combine
import Foundation
import SwiftUI
import WatchConnectivity

import com_awareframework_ios_core
import com_awareframework_ios_sensor_applewatch_shared
import com_awareframework_ios_sensor_applewatch_watchOS

/// Runs the AWARE sensors on the watch, configured by the paired iPhone.
///
/// The phone answers a `get_settings` request with the `AppleWatchDevice`
/// configuration from the deployed CARP study protocol, so this controller
/// holds no study-specific configuration of its own - only defaults used until
/// the phone has been heard from.
@MainActor
final class CarpWatchSensorController: NSObject, ObservableObject {

    // MARK: - Published state (for the UI)

    @Published private(set) var isRunning = false
    @Published private(set) var statusMessage = "Not started"
    @Published private(set) var activeSensorCount = 0
    @Published private(set) var lastTransferAt: Date?
    @Published private(set) var isPhoneReachable = false

    /// The AWARE device id of this watch. Handy to show in a debug screen.
    let deviceId = AwareUtils.getCommonDeviceId()

    // MARK: - Settings received from the phone

    private var backgroundSessionType: AWBackgroundSessionType = .microphone
    private var transferInterval: TimeInterval = 15 * 60
    private var transferIncrementally = true
    private var deleteAfterTransfer = true

    private var enabled: [String: Bool] = [
        "motion": true,
        "battery": true,
        "device": true,
        "heartRate": true,
        "location": false,
        "heading": false,
        "bluetooth": false,
        "audio": false,
    ]

    private var transferTimer: Timer?
    private var hasAppliedPhoneSettings = false
    private var hasActivated = false

    /// When the outstanding `get_settings` request was sent, so overlapping
    /// requests can be suppressed without latching. See `applyPhoneSettings()`.
    private var lastSettingsRequestAt: Date?
    private static let settingsRequestTimeout: TimeInterval = 10

    // MARK: - Sensors

    private lazy var motion = AWMotionSensor(AWMotionSensor.Config().apply { config in
        config.motionSensorHz = 10
        config.saveIntervalSeconds = 10
        config.activateAccelerometerSensor = true
        config.activateDeviceMotionSensor = true
        // Gyroscope and magnetometer are covered by device motion - leaving
        // them on doubles the data volume for very little extra information.
        config.activateGyroscopeSensor = false
        config.activateMagnetometerSensor = false
    })

    private lazy var battery = AWBatterySensor(AWBatterySensor.Config().apply { config in
        config.intervalSeconds = 60
    })

    private lazy var device = AWDeviceSensor(AWDeviceSensor.Config())

    private lazy var heartRate = AWHeartRateSensor(AWHeartRateSensor.Config())

    private lazy var location = AWLocationSensor(AWLocationSensor.Config())

    private lazy var heading = AWHeadingSensor(AWHeadingSensor.Config())

    private lazy var bluetooth = AWBluetoothSensor(AWBluetoothSensor.Config().apply { config in
        config.sensingDurationSeconds = 10
        config.sleepDurationSeconds = 50
    })

    private lazy var audio = AWAudioSensor(AWAudioSensor.Config().apply { config in
        config.activateAmbientNoiseSensor = true
        config.activateAudioClassificationSensor = true
        // Never store raw audio - the phone side of this package does not
        // accept it, and a study that records audio needs a very different
        // consent process.
        config.activateRawAudioSensor = false
        config.dutyCycleEnabled = true
        config.activeDuration = 60
        config.restDuration = 180
        config.storeOnlyTopK = 5
    })

    // MARK: - Lifecycle

    /// Called when the watch app appears. Resumes sampling if it was running
    /// when the app was last closed, and asks the phone for the study settings.
    func activate() {
        // `onAppear` can fire more than once for the same view. Re-running the
        // body would call `start()` again, and `start()` tears the whole sensor
        // set down before rebuilding it - dropping the background session and
        // re-prompting for HealthKit in the middle of a session.
        guard !hasActivated else {
            updateReachability()
            return
        }
        hasActivated = true

        isRunning = UserDefaults.standard.bool(forKey: Self.isRunningKey)

        // Touching `.shared` activates the WCSession, but activation is
        // asynchronous - the session is *not* reachable by the time this
        // returns. Install the state handler so the settings request is retried
        // once activation completes; without it a cold launch always loses the
        // race, and the watch keeps sampling with the built-in defaults until
        // the participant happens to tap "Reload settings".
        AWWCSessionManager.shared.sessionStateChangeHandler = { [weak self] _, activationState in
            Task { @MainActor in
                guard let self else { return }
                self.updateReachability()
                if activationState == .activated { self.applyPhoneSettings() }
            }
        }

        // Chunk size and format only matter for how the data is packed; leave
        // the columnar format on, it is 3-5x smaller than row-oriented JSON.
        AWDataTransferManager.shared.useColumnarFormat = true
        AWDataTransferManager.shared.recordsPerChunk = 500

        updateReachability()
        // Covers the warm launch where the session is already activated and no
        // further state change is coming. A no-op while unreachable.
        applyPhoneSettings()
        if isRunning { start() }
    }

    /// Ask the phone for the study configuration and apply it.
    ///
    /// Safe to call at any time - if the phone cannot be reached the call
    /// simply has no effect, and the sensors keep running with whatever
    /// configuration they already have.
    func applyPhoneSettings() {
        guard WCSession.default.isReachable else {
            if !hasAppliedPhoneSettings { statusMessage = "Waiting for the phone…" }
            return
        }

        // `activate()` asks directly *and* through the session state handler, and
        // the participant can ask again from the UI. Without this guard two
        // replies can land together and both drive `start()`, which tears the
        // sensor set down and back up underneath the other one.
        //
        // The guard has to expire on its own rather than be a plain in-flight
        // flag: AWARE sends `get_settings` via `sendMessage` with no error
        // handler, so a request that fails is never called back at all and a
        // flag would latch on forever.
        if let requestedAt = lastSettingsRequestAt,
           Date().timeIntervalSince(requestedAt) < Self.settingsRequestTimeout {
            return
        }
        lastSettingsRequestAt = Date()

        AWWCSessionManager.shared.applyiPhoneSettings { [weak self] settings in
            Task { @MainActor in
                guard let self else { return }
                self.lastSettingsRequestAt = nil
                self.apply(settings: settings)
            }
        }
    }

    /// Map the settings sent by `AppleWatchDevice` onto the AWARE sensors.
    private func apply(settings: [String: Any]) {
        // `applyiPhoneSettings` already applied `label`, `db_host`, and `debug`
        // to every sensor registered in AWSensorManager. Everything below has
        // to be applied by hand, because only we know which sensors exist.

        if let hz = settings["motion_sensor_hz"] as? Int {
            motion.CONFIG.motionSensorHz = hz
        }
        if let value = settings["watch_motion_accelerometer_enabled"] as? Bool {
            motion.CONFIG.activateAccelerometerSensor = value
        }
        if let value = settings["watch_motion_device_motion_enabled"] as? Bool {
            motion.CONFIG.activateDeviceMotionSensor = value
        }

        if let value = settings["watch_audio_ambient_noise_enabled"] as? Bool {
            audio.CONFIG.activateAmbientNoiseSensor = value
        }
        if let value = settings["watch_audio_classification_enabled"] as? Bool {
            audio.CONFIG.activateAudioClassificationSensor = value
        }
        if let value = settings["watch_audio_duty_cycle_enabled"] as? Bool {
            audio.CONFIG.dutyCycleEnabled = value
        }
        if let value = settings["watch_audio_active_duration"] as? Double {
            audio.CONFIG.activeDuration = value
        }
        if let value = settings["watch_audio_rest_duration"] as? Double {
            audio.CONFIG.restDuration = value
        }

        enabled["motion"] = settings["watch_motion_enabled"] as? Bool ?? enabled["motion"]!
        enabled["battery"] = settings["watch_battery_enabled"] as? Bool ?? enabled["battery"]!
        enabled["device"] = settings["watch_device_enabled"] as? Bool ?? enabled["device"]!
        enabled["heartRate"] = settings["watch_healthkit_enabled"] as? Bool ?? enabled["heartRate"]!
        enabled["location"] = settings["watch_location_enabled"] as? Bool ?? enabled["location"]!
        enabled["heading"] = settings["watch_heading_enabled"] as? Bool ?? enabled["heading"]!
        enabled["bluetooth"] = settings["watch_bluetooth_enabled"] as? Bool ?? enabled["bluetooth"]!
        enabled["audio"] = settings["watch_audio_enabled"] as? Bool ?? enabled["audio"]!

        backgroundSessionType = AWBackgroundSessionType(
            rawValueOrDefault: settings["watch_background_session_type"] as? String
        )

        if let seconds = settings["file_transfer_interval_seconds"] as? Double, seconds > 0 {
            transferInterval = seconds
        }
        transferIncrementally =
            (settings["watch_transfer_mode"] as? String ?? "incremental") == "incremental"
        deleteAfterTransfer = settings["watch_delete_after_transfer"] as? Bool ?? true

        hasAppliedPhoneSettings = true
        statusMessage = "Configured by the phone"

        // Restart so the new configuration takes effect right away.
        if isRunning { start() }
    }

    // MARK: - Start / stop

    func start() {
        let sensors = selectedSensors()
        guard !sensors.isEmpty else {
            stop()
            statusMessage = "No sensors enabled"
            return
        }

        AWSensorManager.shared.set(sensors: sensors) { [weak self] in
            guard let self else { return }

            // Asks for HealthKit authorization if a heart rate sensor is in the
            // set. On watchOS the prompt is shown on the watch.
            AWSensorManager.shared.requestPermissionHealthKit { _, _ in }

            AWSensorManager.shared.start(backgroundSessionType: self.backgroundSessionType) {
                Task { @MainActor in
                    self.isRunning = true
                    self.activeSensorCount = sensors.count
                    self.statusMessage = "Collecting from \(sensors.count) sensors"
                    self.persistRunningState()
                    self.scheduleTransfers()
                    self.updateReachability()
                }
            }
        }
    }

    func stop() {
        transferTimer?.invalidate()
        transferTimer = nil

        AWSensorManager.shared.stop { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.isRunning = false
                self.activeSensorCount = 0
                self.statusMessage = "Stopped"
                self.persistRunningState()
            }
        }
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func selectedSensors() -> [AwareSensor] {
        var sensors: [AwareSensor] = []
        if enabled["motion"] == true { sensors.append(motion) }
        if enabled["battery"] == true { sensors.append(battery) }
        if enabled["device"] == true { sensors.append(device) }
        if enabled["heartRate"] == true { sensors.append(heartRate) }
        if enabled["location"] == true { sensors.append(location) }
        if enabled["heading"] == true { sensors.append(heading) }
        if enabled["bluetooth"] == true { sensors.append(bluetooth) }
        if enabled["audio"] == true { sensors.append(audio) }
        return sensors
    }

    // MARK: - Transferring data to the phone

    private func scheduleTransfers() {
        transferTimer?.invalidate()
        transferTimer = Timer.scheduledTimer(
            withTimeInterval: transferInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.transferNow() }
        }
    }

    /// Hand everything collected so far to the phone.
    ///
    /// `WCSession.transferFile` queues the files, so this works even when the
    /// phone is out of range - the OS delivers them when it comes back.
    func transferNow() {
        // Guard on what the transfer actually reads. `transferAllData` and
        // `transferIncrementalData` pull from `AWSensorManager.shared.sensors`,
        // which is only populated once `start()` has run - checking
        // `selectedSensors()` here instead would report "Transfer complete"
        // after sending nothing, and would instantiate every enabled sensor
        // just to count them.
        guard !AWSensorManager.shared.sensors.isEmpty else { return }

        statusMessage = "Transferring…"

        let completion: (Error?) -> Void = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.statusMessage = "Transfer failed: \(error.localizedDescription)"
                } else {
                    self.lastTransferAt = Date()
                    self.statusMessage = self.isRunning
                        ? "Collecting from \(self.activeSensorCount) sensors"
                        : "Transfer complete"
                }
                self.updateReachability()
            }
        }

        if transferIncrementally {
            AWSensorManager.shared.transferIncrementalData(
                deleteAfterTransfer: deleteAfterTransfer,
                completion: completion
            )
        } else {
            AWSensorManager.shared.transferAllData(
                deleteAfterTransfer: deleteAfterTransfer,
                completion: completion
            )
        }
    }

    // MARK: - Helpers

    private static let isRunningKey = "carp_watch_is_running"

    private func persistRunningState() {
        UserDefaults.standard.set(isRunning, forKey: Self.isRunningKey)
    }

    /// Re-read whether the phone is in range.
    ///
    /// `AWWCSessionManager` owns the `WCSessionDelegate` and does not forward
    /// `sessionReachabilityDidChange`, so the indicator cannot update itself.
    /// The app refreshes it whenever the watch app comes back to the front,
    /// which is the only moment anyone is looking at it.
    func refreshReachability() {
        updateReachability()
    }

    private func updateReachability() {
        isPhoneReachable = WCSession.isSupported() && WCSession.default.isReachable
    }
}
