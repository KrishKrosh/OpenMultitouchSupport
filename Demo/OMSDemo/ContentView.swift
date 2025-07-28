//
//  ContentView.swift
//  OMSDemo
//
//  Created by Takuto Nakamura on 2024/03/02.
//

import OpenMultitouchSupport
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            // Device Selector
            if !viewModel.availableDevices.isEmpty {
                VStack(alignment: .leading) {
                    Text("Trackpad Device:")
                        .font(.headline)
                    Picker("Select Device", selection: Binding(
                        get: { viewModel.selectedDevice },
                        set: { device in
                            if let device = device {
                                viewModel.selectDevice(device)
                            }
                        }
                    )) {
                        ForEach(viewModel.availableDevices, id: \.self) { device in
                            Text("\(device.deviceName) (ID: \(device.deviceID))")
                                .tag(device as OMSDeviceInfo?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.bottom)
            }
            
            HStack(spacing: 20) {
                if viewModel.isListening {
                    Button {
                        viewModel.stop()
                    } label: {
                        Text("Stop")
                    }
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.onButtonHover()
                        } else {
                            viewModel.onButtonExitHover()
                        }
                    }
                } else {
                    Button {
                        viewModel.start()
                    } label: {
                        Text("Start")
                    }
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.onButtonHover()
                        } else {
                            viewModel.onButtonExitHover()
                        }
                    }
                }
                
                if viewModel.isHapticEnabled {
                    Button {
                        viewModel.stopHaptics()
                    } label: {
                        Text("Stop Haptics")
                            .foregroundColor(.red)
                    }
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.onButtonHover()
                        } else {
                            viewModel.onButtonExitHover()
                        }
                    }
                } else {
                    Button {
                        viewModel.startHaptics()
                    } label: {
                        Text("Start Haptics")
                            .foregroundColor(.green)
                    }
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.onButtonHover()
                        } else {
                            viewModel.onButtonExitHover()
                        }
                    }
                }
            }
            
            // Raw Haptic Testing Section
            if viewModel.isHapticEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Raw Haptic Testing:")
                        .font(.headline)
                    
                    Text("Known Working IDs: 1, 2, 3, 4, 5, 6, 15, 16")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actuation ID:")
                                .font(.caption)
                            TextField("ID", text: $viewModel.customActuationID)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unknown1 (UInt32):")
                                .font(.caption)
                            TextField("0", text: $viewModel.customUnknown1)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unknown2 (Float):")
                                .font(.caption)
                            TextField("1.0", text: $viewModel.customUnknown2)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unknown3 (Float):")
                                .font(.caption)
                            TextField("2.0", text: $viewModel.customUnknown3)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Button("Trigger") {
                            viewModel.triggerRawHaptic()
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [])
                    }
                    .onSubmit {
                        viewModel.triggerRawHaptic()
                    }
                }
                .padding(.bottom)
            }
            
            Canvas { context, size in
                viewModel.touchData.forEach { touch in
                    let path = makeEllipse(touch: touch, size: size)
                    context.fill(path, with: .color(.primary.opacity(Double(touch.total))))
                }
            }
            .frame(width: 600, height: 400)
            .border(Color.primary)
        }
        .fixedSize()
        .padding()
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            viewModel.ensureHapticsSafe()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willHideNotification)) { _ in
            viewModel.ensureHapticsSafe()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            viewModel.ensureHapticsSafe()
        }
    }

    private func makeEllipse(touch: OMSTouchData, size: CGSize) -> Path {
        let x = Double(touch.position.x) * size.width
        let y = Double(1.0 - touch.position.y) * size.height
        let u = size.width / 100.0
        let w = Double(touch.axis.major) * u
        let h = Double(touch.axis.minor) * u
        return Path(ellipseIn: CGRect(x: -0.5 * w, y: -0.5 * h, width: w, height: h))
            .rotation(.radians(Double(-touch.angle)), anchor: .topLeading)
            .offset(x: x, y: y)
            .path(in: CGRect(origin: .zero, size: size))
    }
}

#Preview {
    ContentView()
}
