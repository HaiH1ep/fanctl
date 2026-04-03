import Foundation
import IOKit

public enum SMCDiagnostic {
    public static func run() {
        print("=== STRUCT LAYOUT ===")
        print("SMCKeyData_t size=\(MemoryLayout<SMCKeyData_t>.size) stride=\(MemoryLayout<SMCKeyData_t>.stride)")

        print("  vers offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.vers)!)")
        print("  pLimitData offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.pLimitData)!)")
        print("  keyInfo offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.keyInfo)!)")
        print("  result offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.result)!)")
        print("  status offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.status)!)")
        print("  data8 offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.data8)!)")
        print("  data32 offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.data32)!)")
        print("  bytes offset = \(MemoryLayout<SMCKeyData_t>.offset(of: \.bytes)!)")

        let smc = SMCConnection()
        do { try smc.open() } catch { print("ERROR: \(error)"); return }
        defer { smc.close() }

        // Raw key count - dump raw bytes to find where count lives
        print("\n=== RAW KEY COUNT ===")
        do {
            var input = SMCKeyData_t()
            input.data8 = 7 // getKeyCount
            var output = SMCKeyData_t()
            var outSize = MemoryLayout<SMCKeyData_t>.stride

            var rawConn: io_connect_t = 0
            let svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
            IOServiceOpen(svc, mach_task_self_, 0, &rawConn)
            IOObjectRelease(svc)

            let r = IOConnectCallStructMethod(rawConn, 2, &input, MemoryLayout<SMCKeyData_t>.stride, &output, &outSize)
            IOServiceClose(rawConn)
            print("result=\(r) data32=\(output.data32)")
            withUnsafeBytes(of: &output) { ptr in
                let bytes = Array(ptr)
                print("Raw output bytes [0..20]: \(bytes[0..<20].map { String(format: "%02x", $0) }.joined(separator: " "))")
                print("Raw output bytes [38..56]: \(bytes[38..<min(56, bytes.count)].map { String(format: "%02x", $0) }.joined(separator: " "))")
                for off in [40, 41, 42, 44] where off + 4 <= bytes.count {
                    let slice = Array(bytes[off..<off+4])
                    let valLE = UInt32(slice[0]) | UInt32(slice[1]) << 8 | UInt32(slice[2]) << 16 | UInt32(slice[3]) << 24
                    let valBE = UInt32(slice[0]) << 24 | UInt32(slice[1]) << 16 | UInt32(slice[2]) << 8 | UInt32(slice[3])
                    print("  UInt32 at \(off): LE=\(valLE) BE=\(valBE)")
                }
            }
        }

        // Skip enumeration, just try known keys directly
        print("\n=== FAN INFO ===")
        for key in ["FNum"] {
            if let val = try? smc.readKey(key) {
                print("\(key): type=\(val.dataType) size=\(val.dataSize) bytes=\(val.bytes.map { String(format: "%02x", $0) }.joined(separator: " ")) decoded=\(decodeSmcValue(val))")
            } else {
                print("\(key): NOT FOUND")
            }
        }

        let fanCount = (try? smc.readKey("FNum")).map { uint8FromBytes($0.bytes) } ?? 0
        print("Fan count: \(fanCount)")
        for i in 0..<Int(fanCount) {
            for key in [FanKeys.actualSpeed(i), FanKeys.minSpeed(i), FanKeys.maxSpeed(i), FanKeys.targetSpeed(i), FanKeys.mode(i), FanKeys.fanID(i)] {
                if let val = try? smc.readKey(key) {
                    print("  \(key): type=\(val.dataType) size=\(val.dataSize) decoded=\(decodeSmcValue(val)) raw=\(val.bytes.prefix(Int(val.dataSize)).map { String(format: "%02x", $0) }.joined(separator: " "))")
                } else {
                    print("  \(key): NOT FOUND")
                }
            }
        }

        // Try M4 Pro temperature keys
        print("\n=== M4 PRO TEMPERATURE KEYS ===")
        let tempKeys = ["Te05", "Te0S", "Te09", "Te0H",
                        "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0V", "Tp0Y", "Tp0b", "Tp0e",
                        "Tg0G", "Tg0H", "Tg1U", "Tg1k",
                        "TB0T", "TW0P", "Tm0P", "TA0P", "PSTR"]
        for key in tempKeys {
            if let val = try? smc.readKey(key) {
                print("  \(key) = \(String(format: "%.1f", decodeSmcValue(val)))°C  type=\(val.dataType)")
            }
        }

        // Also try M3-style keys in case M4 Pro uses those
        print("\n=== M3-STYLE KEYS ===")
        let m3Keys = ["Te05", "Te0L", "Te0P", "Te0S",
                      "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E",
                      "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E",
                      "Tf14", "Tf18", "Tf19", "Tf1A", "Tf24", "Tf28", "Tf29", "Tf2A"]
        for key in m3Keys {
            if let val = try? smc.readKey(key) {
                print("  \(key) = \(String(format: "%.1f", decodeSmcValue(val)))°C  type=\(val.dataType)")
            }
        }

        // Brute scan T-prefix keys: Ta-Tz, TA-TZ range
        print("\n=== BRUTE SCAN T-PREFIX (Tx00-Tx99, TXxx) ===")
        var found: [(String, Float, String)] = []
        let prefixes = ["Ta","Tb","Tc","Td","Te","Tf","Tg","Th","Ti","Tj","Tk","Tl","Tm","Tn","To","Tp",
                        "TA","TB","TC","TD","TE","TF","TG","TH","TI","TJ","TK","TL","TM","TN","TO","TP",
                        "TQ","TR","TS","TT","TU","TV","TW","TX","TY","TZ"]
        let suffixes = ["00","01","02","03","04","05","06","07","08","09",
                        "0A","0B","0C","0D","0E","0F","0G","0H","0I","0J","0K","0L","0M","0N","0O","0P",
                        "0Q","0R","0S","0T","0U","0V","0W","0X","0Y","0Z",
                        "0a","0b","0c","0d","0e","0f","0g","0h","0i","0j","0k","0l","0m","0n","0o","0p",
                        "1h","1k","1l","1p","1t","1U",
                        "44","49","4A","4B","4D","4E",
                        "14","18","19","1A","24","28","29","2A"]
        for p in prefixes {
            for s in suffixes {
                let key = p + s
                guard key.count == 4 else { continue }
                if let val = try? smc.readKey(key) {
                    let decoded = decodeSmcValue(val)
                    if decoded > 0 && decoded < 150 {
                        found.append((key, decoded, val.dataType))
                    }
                }
            }
        }
        print("Found \(found.count) temperature readings:")
        for (key, temp, type) in found.sorted(by: { $0.0 < $1.0 }) {
            print("  \(key) = \(String(format: "%5.1f", temp))°C  type=\(type)")
        }
    }

    private static func offset<T, F>(_ base: inout T, _ field: inout F, _ basePtr: UnsafeRawPointer) -> Int {
        withUnsafePointer(to: &field) { Int(bitPattern: UnsafeRawPointer($0)) - Int(bitPattern: basePtr) }
    }
}
