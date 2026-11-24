import Foundation

enum JinyinghuaLoanConfig {
    static let annualRate = 0.24
    static let minAmount = 1_000
    static let maxAmount = 8_000
    static let defaultAmountMin = 3_000
    static let amountStep = 100
    static let termMonthsOptions = [3, 6, 12]
    static let defaultTermMonths = 3
    static let repaymentMethod = "等额本息"

    static func randomDefaultAmount() -> Int {
        let steps = (maxAmount - defaultAmountMin) / amountStep
        return defaultAmountMin + Int.random(in: 0...steps) * amountStep
    }
}

struct JinyinghuaLoanCalculation {
    let principal: Double
    let termMonths: Int
    let annualRate: Double
    let monthlyPayment: Double
    let totalInterest: Double
    let totalRepayment: Double
}

enum JinyinghuaLoanCalculator {
    static func calculate(
        principal: Int,
        termMonths: Int,
        annualRate: Double = JinyinghuaLoanConfig.annualRate
    ) -> JinyinghuaLoanCalculation {
        let safePrincipal = Double(max(0, principal))
        let safeTerm = max(1, termMonths)
        let monthlyRate = pow(1 + annualRate, 1.0 / 12.0) - 1
        let factor = pow(1 + monthlyRate, Double(safeTerm))
        let scheduledPayment = safePrincipal == 0 || monthlyRate == 0
            ? safePrincipal / Double(safeTerm)
            : safePrincipal * monthlyRate * factor / (factor - 1)
        let regularPayment = roundMoney(scheduledPayment)

        var remaining = safePrincipal
        var totalRepayment = 0.0
        for period in 1...safeTerm {
            let interest = roundMoney(remaining * monthlyRate)
            let payment = period == safeTerm
                ? roundMoney(remaining + interest)
                : regularPayment
            let principalPayment = roundMoney(payment - interest)
            remaining = roundMoney(max(0, remaining - principalPayment))
            totalRepayment = roundMoney(totalRepayment + payment)
        }

        return JinyinghuaLoanCalculation(
            principal: safePrincipal,
            termMonths: safeTerm,
            annualRate: annualRate,
            monthlyPayment: regularPayment,
            totalInterest: roundMoney(totalRepayment - safePrincipal),
            totalRepayment: totalRepayment
        )
    }

    private static func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
