/*
 OMSManager.swift

 Created by Takuto Nakamura on 2024/03/02.
*/

import Combine
@preconcurrency import OpenMultitouchSupportXCF
import os

public struct OMSDeviceInfo: Sendable, Hashable {
    public let deviceName: String
    public let deviceID: String
    public let isBuiltIn: Bool
#if swift(>=6.0)
    internal nonisolated(unsafe) let deviceInfo: OpenMTDeviceInfo
#else
    internal let deviceInfo: OpenMTDeviceInfo
#endif
    
    internal init(_ deviceInfo: OpenMTDeviceInfo) {
        self.deviceInfo = deviceInfo
        self.deviceName = deviceInfo.deviceName
        self.deviceID = deviceInfo.deviceID
        self.isBuiltIn = deviceInfo.isBuiltIn
    }
}

public final class OMSManager: Sendable {
    public static let shared = OMSManager()

    private let protectedManager: OSAllocatedUnfairLock<OpenMTManager?>
    private let protectedListener = OSAllocatedUnfairLock<OpenMTListener?>(uncheckedState: nil)
    private let dateFormatter = DateFormatter()

    private let touchDataSubject = PassthroughSubject<[OMSTouchData], Never>()
    public var touchDataStream: AsyncStream<[OMSTouchData]> {
        AsyncStream { continuation in
            let cancellable = touchDataSubject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    public var isListening: Bool {
        protectedListener.withLockUnchecked { $0 != nil }
    }
    
    public var availableDevices: [OMSDeviceInfo] {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }) else { return [] }
        return xcfManager.availableDevices().map { OMSDeviceInfo($0) }
    }
    
    public var currentDevice: OMSDeviceInfo? {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }),
              let current = xcfManager.currentDevice() else { return nil }
        return OMSDeviceInfo(current)
    }

    private init() {
        protectedManager = .init(uncheckedState: OpenMTManager.shared())
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"
    }

    @discardableResult
    public func startListening() -> Bool {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }),
              protectedListener.withLockUnchecked({ $0 == nil }) else {
            return false
        }
        let listener = xcfManager.addListener(
            withTarget: self,
            selector: #selector(listen)
        )
        protectedListener.withLockUnchecked { $0 = listener }
        return true
    }

    @discardableResult
    public func stopListening() -> Bool {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }),
              let listener = protectedListener.withLockUnchecked({ $0 }) else {
            return false
        }
        xcfManager.remove(listener)
        protectedListener.withLockUnchecked { $0 = nil }
        return true
    }
    
    @discardableResult
    public func selectDevice(_ device: OMSDeviceInfo) -> Bool {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }) else { return false }
        return xcfManager.selectDevice(device.deviceInfo)
    }
    
    public var isHapticEnabled: Bool {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }) else { return false }
        return xcfManager.isHapticEnabled()
    }
    
    @discardableResult
    public func setHapticEnabled(_ enabled: Bool) -> Bool {
        guard let xcfManager = protectedManager.withLockUnchecked({ $0 }) else { return false }
        return xcfManager.setHapticEnabled(enabled)
    }

    @objc func listen(_ event: OpenMTEvent) {
        guard let touches = (event.touches as NSArray) as? [OpenMTTouch] else { return }
        if touches.isEmpty {
            touchDataSubject.send([])
        } else {
            let array = touches.compactMap { touch -> OMSTouchData? in
                guard let state = OMSState(touch.state) else { return nil }
                return OMSTouchData(
                    id: touch.identifier,
                    position: OMSPosition(x: touch.posX, y: touch.posY),
                    total: touch.total,
                    pressure: touch.pressure,
                    axis: OMSAxis(major: touch.majorAxis, minor: touch.minorAxis),
                    angle: touch.angle,
                    density: touch.density,
                    state: state,
                    timestamp: dateFormatter.string(from: Date.now)
                )
            }
            touchDataSubject.send(array)
        }
    }
}

#if swift(>=6.0)
extension AnyCancellable: @retroactive @unchecked Sendable {}
extension PassthroughSubject: @retroactive @unchecked Sendable {}
#else
import _Concurrency
extension AnyCancellable: @unchecked Sendable {}
extension PassthroughSubject: @unchecked Sendable {}
#endif