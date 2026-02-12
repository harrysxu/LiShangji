//
//  AppConstantsTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import SwiftUI
@testable import LiShangJi

// MARK: - Brand Constants

struct BrandConstantsTests {

    @Test func appName() {
        #expect(AppConstants.Brand.appName == "礼小记")
    }

    @Test func slogan() {
        #expect(AppConstants.Brand.slogan == "懂礼数，更懂你")
    }

    @Test func version() {
        #expect(AppConstants.Brand.version == "1.0")
    }
}

// MARK: - Spacing Constants

struct SpacingConstantsTests {

    @Test func spacingValues() {
        #expect(AppConstants.Spacing.xs == 4)
        #expect(AppConstants.Spacing.sm == 8)
        #expect(AppConstants.Spacing.md == 12)
        #expect(AppConstants.Spacing.lg == 16)
        #expect(AppConstants.Spacing.xl == 20)
        #expect(AppConstants.Spacing.xxl == 24)
        #expect(AppConstants.Spacing.xxxl == 32)
    }
}

// MARK: - Radius Constants

struct RadiusConstantsTests {

    @Test func radiusValues() {
        #expect(AppConstants.Radius.sm == 8)
        #expect(AppConstants.Radius.md == 12)
        #expect(AppConstants.Radius.lg == 16)
        #expect(AppConstants.Radius.xl == 20)
    }
}

// MARK: - PagePadding Constants

struct PagePaddingConstantsTests {

    @Test func pagePaddingValues() {
        #expect(AppConstants.PagePadding.iPhone == 16)
        #expect(AppConstants.PagePadding.iPad == 20)
    }
}

// MARK: - Animation Constants

struct AnimationConstantsTests {

    @Test func animationValues() {
        #expect(AppConstants.Animation.springResponse == 0.4)
        #expect(AppConstants.Animation.springDamping == 0.8)
        #expect(AppConstants.Animation.quickDuration == 0.2)
        #expect(AppConstants.Animation.normalDuration == 0.3)
    }
}

// MARK: - Keypad Constants

struct KeypadConstantsTests {

    @Test func keypadValues() {
        #expect(AppConstants.Keypad.keyMinSize == 52)
        #expect(AppConstants.Keypad.keySpacing == 8)
    }
}
