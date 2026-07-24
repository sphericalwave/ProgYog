//
//  HeartRateService.swift
//  ProgYog
//
//  Bluetooth LE Heart Rate Profile (0x180D / 0x2A37).
//

import Foundation
import CoreBluetooth
import Combine
import DiagnosticsKit

/// User max-heart-rate setting, persisted via `@AppStorage`. The default is
/// the `220 − age` estimate; a non-zero manual override replaces it.
enum HRSettings {
    static let ageKey = "userAge"
    static let overrideKey = "hrMaxOverride"

    /// `manualOverride == 0` means "no override — use the 220 − age estimate".
    static func effectiveMax(age: Int, manualOverride: Int) -> Int {
        manualOverride > 0 ? manualOverride : max(220 - age, 1)
    }
}

@MainActor
final class HeartRateService: NSObject, ObservableObject {
    @Published private(set) var bpm: Int?
    @Published private(set) var state: ConnectionState = .idle
    @Published private(set) var discovered: [CBPeripheral] = []
    weak var errorLog: ErrorLog?

    enum ConnectionState: Equatable {
        case idle
        case bluetoothOff
        case unauthorized
        case scanning
        case connecting
        case connected(name: String)
        case disconnected

        var label: String {
            switch self {
            case .idle: return "Connect HR"
            case .bluetoothOff: return "Bluetooth off"
            case .unauthorized: return "Permission needed"
            case .scanning: return "Scanning…"
            case .connecting: return "Connecting…"
            case .connected(let name): return name
            case .disconnected: return "Reconnect"
            }
        }
    }

    struct Sample: Equatable {
        let t: Date
        let bpm: Int
    }

    private nonisolated static let hrServiceUUID = CBUUID(string: "180D")
    private nonisolated static let hrMeasurementUUID = CBUUID(string: "2A37")

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var wantsScan = false
    private var sampleContinuation: AsyncStream<Sample>.Continuation?

    lazy var samples: AsyncStream<Sample> = {
        AsyncStream { continuation in
            self.sampleContinuation = continuation
        }
    }()

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        wantsScan = true
        discovered.removeAll()
        switch central.state {
        case .poweredOn:
            state = .scanning
            central.scanForPeripherals(withServices: [Self.hrServiceUUID])
        case .poweredOff:
            state = .bluetoothOff
        case .unauthorized:
            state = .unauthorized
        default:
            state = .scanning
        }
    }

    func stopScan() {
        wantsScan = false
        central.stopScan()
        if case .scanning = state { state = .idle }
    }

    func connect(_ peripheral: CBPeripheral) {
        wantsScan = false
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        state = .connecting
        central.connect(peripheral)
    }

    func disconnect() {
        if let p = peripheral {
            p.delegate = nil
            central.cancelPeripheralConnection(p)
        }
        peripheral = nil
    }
}

extension HeartRateService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                if self.wantsScan {
                    self.state = .scanning
                    central.scanForPeripherals(withServices: [Self.hrServiceUUID])
                }
            case .poweredOff:
                self.state = .bluetoothOff
                self.bpm = nil
            case .unauthorized:
                self.state = .unauthorized
            case .unsupported:
                self.state = .bluetoothOff
            case .resetting, .unknown:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            if !self.discovered.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discovered.append(peripheral)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.state = .connected(name: peripheral.name ?? "HR Monitor")
            peripheral.discoverServices([Self.hrServiceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.state = .disconnected
            self.errorLog?.warning("BLE.connect", "Failed to connect to \(peripheral.name ?? "device")", error: error)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.state = .disconnected
            self.bpm = nil
            if let error {
                self.errorLog?.warning("BLE.disconnect", "Disconnected from \(peripheral.name ?? "device")", error: error)
            }
        }
    }
}

extension HeartRateService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.hrServiceUUID }) else { return }
        peripheral.discoverCharacteristics([Self.hrMeasurementUUID], for: service)
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == Self.hrMeasurementUUID }) else { return }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == Self.hrMeasurementUUID,
              let data = characteristic.value,
              let bpm = Self.parseHRMeasurement(data) else { return }
        let sample = Sample(t: Date(), bpm: bpm)
        Task { @MainActor in
            self.bpm = bpm
            self.sampleContinuation?.yield(sample)
        }
    }

    nonisolated static func parseHRMeasurement(_ data: Data) -> Int? {
        guard let first = data.first else { return nil }
        let isUInt16 = (first & 0x01) == 0x01
        if isUInt16 {
            guard data.count >= 3 else { return nil }
            let lo = UInt16(data[1])
            let hi = UInt16(data[2])
            return Int((hi << 8) | lo)
        } else {
            guard data.count >= 2 else { return nil }
            return Int(data[1])
        }
    }
}
