import Foundation

public struct ChipIdentifier {
    public static func detect() -> ChipGeneration {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return .unknown }

        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        let brandString = String(cString: brand).lowercased()

        if brandString.contains("m4 max") { return .m4Max }
        if brandString.contains("m4 pro") { return .m4Pro }
        if brandString.contains("m4") { return .m4 }
        if brandString.contains("m3 max") { return .m3Max }
        if brandString.contains("m3 pro") { return .m3Pro }
        if brandString.contains("m3") { return .m3 }
        if brandString.contains("m2 ultra") { return .m2Ultra }
        if brandString.contains("m2 max") { return .m2Max }
        if brandString.contains("m2 pro") { return .m2Pro }
        if brandString.contains("m2") { return .m2 }
        if brandString.contains("m1 ultra") { return .m1Ultra }
        if brandString.contains("m1 max") { return .m1Max }
        if brandString.contains("m1 pro") { return .m1Pro }
        if brandString.contains("m1") { return .m1 }

        return .unknown
    }

    public static var brandString: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "Unknown" }
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        return String(cString: brand)
    }
}
