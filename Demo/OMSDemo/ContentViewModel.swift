//
//  ContentViewModel.swift
//  OMSDemo
//
//  Created by Takuto Nakamura on 2024/03/02.
//

import OpenMultitouchSupport
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var touchData = [OMSTouchData]()
    @Published var isListening: Bool = false
    @Published var availableDevices = [OMSDeviceInfo]()
    @Published var selectedDevice: OMSDeviceInfo?
    @Published var isHapticEnabled: Bool = false

    private let manager = OMSManager.shared
    private var task: Task<Void, Never>?
    private var hapticStateBeforeHover: Bool = true
    private var isCurrentlyHovering: Bool = false
    private var safetyTimer: Timer?

    init() {
        loadDevices()
    }

    func onAppear() {
        task = Task { [weak self, manager] in
            for await touchData in manager.touchDataStream {
                await MainActor.run {
                    self?.touchData = touchData
                }
            }
        }
        
        // Start safety timer to periodically check haptic state
        safetyTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateHapticStatus()
            }
        }
    }

    func onDisappear() {
        task?.cancel()
        safetyTimer?.invalidate()
        safetyTimer = nil
        stop()
        
        // Safety: Ensure haptics are restored when view disappears
        ensureHapticsSafe()
    }
    
    deinit {
        // Final safety check: Ensure haptics are enabled during cleanup
        if !manager.isHapticEnabled {
            print("⚠️ Restoring haptics during ViewModel cleanup")
            manager.setHapticEnabled(true)
        }
    }

    func start() {
        if manager.startListening() {
            isListening = true
        }
    }

    func stop() {
        if manager.stopListening() {
            isListening = false
        }
    }
    
    func loadDevices() {
        availableDevices = manager.availableDevices
        selectedDevice = manager.currentDevice
        updateHapticStatus()
    }
    
    func selectDevice(_ device: OMSDeviceInfo) {
        if manager.selectDevice(device) {
            selectedDevice = device
            updateHapticStatus()
        }
    }
    
    func startHaptics() {
        if manager.setHapticEnabled(true) {
            isHapticEnabled = true
            // Update the hover state since user explicitly changed haptics
            hapticStateBeforeHover = true
        }
    }
    
    func stopHaptics() {
        if manager.setHapticEnabled(false) {
            isHapticEnabled = false
            // Update the hover state since user explicitly changed haptics
            hapticStateBeforeHover = false
        }
    }
    
    func updateHapticStatus() {
        isHapticEnabled = manager.isHapticEnabled
    }
    
    func onButtonHover() {
        // Only save the state when we first start hovering
        if !isCurrentlyHovering {
            hapticStateBeforeHover = manager.isHapticEnabled
            isCurrentlyHovering = true
            print("🎯 Starting hover - saving haptic state: \(hapticStateBeforeHover)")
        }
        
        if !manager.isHapticEnabled {
            print("🎯 Temporarily enabling haptics for button hover")
            manager.setHapticEnabled(true)
        }
    }
    
    func onButtonExitHover() {
        if isCurrentlyHovering {
            isCurrentlyHovering = false
            if !hapticStateBeforeHover {
                print("🎯 Restoring previous haptic state after hover: \(hapticStateBeforeHover)")
                manager.setHapticEnabled(false)
            } else {
                print("🎯 Keeping haptics enabled after hover")
            }
        }
    }
    
    func ensureHapticsSafe() {
        if !manager.isHapticEnabled {
            print("⚠️ Safety check: Restoring haptics to prevent trackpad issues")
            manager.setHapticEnabled(true)
            updateHapticStatus()
        }
    }
}
