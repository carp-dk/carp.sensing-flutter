//
//  ContentView.swift
//  CARPWatch Watch App
//
//  Created by Alireza Hajebrahimi on 17/08/2026.
//
import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: CarpWatchSensorController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    controller.isRunning ? "Collecting" : "Stopped",
                    systemImage: controller.isRunning ? "waveform.path.ecg" : "pause.circle"
                )
                .font(.headline)

                Text(controller.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Label(
                    controller.isPhoneReachable ? "Phone reachable" : "Phone out of range",
                    systemImage: controller.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                if let lastTransferAt = controller.lastTransferAt {
                    Text("Last transfer: \(lastTransferAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button(controller.isRunning ? "Stop" : "Start") {
                    controller.toggle()
                }
                .tint(controller.isRunning ? .red : .green)

                Button("Send data to phone") {
                    controller.transferNow()
                }

                Button("Reload settings") {
                    controller.applyPhoneSettings()
                }
                .font(.footnote)
            }
            .padding(.horizontal, 4)
        }
    }
}
