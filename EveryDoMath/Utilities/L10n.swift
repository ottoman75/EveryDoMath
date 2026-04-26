import Foundation

// 다국어 포맷 문자열 헬퍼 — NSLocalizedString + String(format:) 단축
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    if args.isEmpty { return format }
    return String(format: format, arguments: args)
}
