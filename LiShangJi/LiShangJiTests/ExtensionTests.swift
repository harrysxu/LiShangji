//
//  ExtensionTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import Foundation
@testable import LiShangJi

// MARK: - Double+Currency Tests

struct DoubleCurrencyTests {

    // MARK: - currencyString

    @Test func currencyStringWholeNumber() {
        let result = Double(1000).currencyString
        #expect(result == "¥1,000")
    }

    @Test func currencyStringDecimal() {
        let result = Double(88.5).currencyString
        #expect(result == "¥88.50")
    }

    @Test func currencyStringZero() {
        let result = Double(0).currencyString
        #expect(result == "¥0")
    }

    @Test func currencyStringLargeNumber() {
        let result = Double(100000).currencyString
        #expect(result == "¥100,000")
    }

    // MARK: - amountString

    @Test func amountStringWholeNumber() {
        let result = Double(1000).amountString
        #expect(result == "1,000")
    }

    @Test func amountStringDecimal() {
        let result = Double(88.5).amountString
        #expect(result == "88.5")
    }

    @Test func amountStringZero() {
        let result = Double(0).amountString
        #expect(result == "0")
    }

    // MARK: - balanceString

    @Test func balanceStringPositive() {
        let result = Double(500).balanceString
        #expect(result == "+¥500")
    }

    @Test func balanceStringNegative() {
        let result = Double(-300).balanceString
        #expect(result == "-¥300")
    }

    @Test func balanceStringZero() {
        let result = Double(0).balanceString
        #expect(result == "¥0")
    }

    // MARK: - chineseUppercase

    @Test func chineseUppercaseZero() {
        #expect(Double(0).chineseUppercase == "零元整")
    }

    @Test func chineseUppercaseThousand() {
        #expect(Double(1000).chineseUppercase == "壹仟元整")
    }

    @Test func chineseUppercase888() {
        #expect(Double(888).chineseUppercase == "捌佰捌拾捌元整")
    }

    @Test func chineseUppercase666() {
        #expect(Double(666).chineseUppercase == "陆佰陆拾陆元整")
    }

    @Test func chineseUppercaseTenThousand() {
        #expect(Double(10000).chineseUppercase == "壹万元整")
    }

    @Test func chineseUppercase100() {
        #expect(Double(100).chineseUppercase == "壹佰元整")
    }
}
