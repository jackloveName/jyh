import Foundation

enum PasswordPolicy {
    static let ruleDescription = "密码需为 8–20 位半角字符，并同时包含字母、数字和特殊符号"

    static func removingWhitespace(from value: String) -> String {
        String(value.filter { !$0.isWhitespace })
    }

    static func isValid(_ value: String) -> Bool {
        let scalars = value.unicodeScalars
        guard (8...20).contains(scalars.count),
              scalars.allSatisfy({ (0x21...0x7E).contains($0.value) }) else {
            return false
        }

        let hasLetter = scalars.contains { CharacterSet.letters.contains($0) }
        let hasDigit = scalars.contains { CharacterSet.decimalDigits.contains($0) }
        let hasSpecial = scalars.contains {
            !CharacterSet.letters.contains($0) && !CharacterSet.decimalDigits.contains($0)
        }
        return hasLetter && hasDigit && hasSpecial
    }
}
