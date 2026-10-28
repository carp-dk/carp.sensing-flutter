//
//  CARPWatchApp.swift
//  CARPWatch Watch App
//
//  Created by Alireza Hajebrahimi on 17/08/2026.
//

import SwiftUI

@main
struct CARPWatch_Watch_AppApp: App {
    @StateObject private var controller = CarpWatchSensorController()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
                .onAppear { controller.activate() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            // Hand whatever has been collected to the phone before the app is
            // suspended, so nothing is left behind if the app is terminated.
            case .background: controller.transferNow()
            // Nothing forwards WatchConnectivity reachability changes while the
            // app is away, so the indicator is refreshed on the way back in.
            case .active: controller.refreshReachability()
            default: break
            }
        }
    }
}
