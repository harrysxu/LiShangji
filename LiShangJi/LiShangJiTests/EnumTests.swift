//
//  EnumTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
@testable import LiShangJi

// MARK: - EventCategory Tests

struct EventCategoryTests {

    @Test func allCasesCount() {
        #expect(EventCategory.allCases.count == 13)
    }

    @Test func rawValues() {
        #expect(EventCategory.wedding.rawValue == "wedding")
        #expect(EventCategory.babyBorn.rawValue == "baby_born")
        #expect(EventCategory.fullMoon.rawValue == "full_moon")
        #expect(EventCategory.firstBirthday.rawValue == "first_birthday")
        #expect(EventCategory.birthday.rawValue == "birthday")
        #expect(EventCategory.funeral.rawValue == "funeral")
        #expect(EventCategory.housewarming.rawValue == "housewarming")
        #expect(EventCategory.graduation.rawValue == "graduation")
        #expect(EventCategory.promotion.rawValue == "promotion")
        #expect(EventCategory.springFestival.rawValue == "spring_festival")
        #expect(EventCategory.midAutumn.rawValue == "mid_autumn")
        #expect(EventCategory.dragonBoat.rawValue == "dragon_boat")
        #expect(EventCategory.other.rawValue == "other")
    }

    @Test func displayNames() {
        #expect(EventCategory.wedding.displayName == "婚礼")
        #expect(EventCategory.babyBorn.displayName == "新生儿")
        #expect(EventCategory.fullMoon.displayName == "满月酒")
        #expect(EventCategory.firstBirthday.displayName == "周岁")
        #expect(EventCategory.birthday.displayName == "生日")
        #expect(EventCategory.funeral.displayName == "丧事")
        #expect(EventCategory.housewarming.displayName == "乔迁")
        #expect(EventCategory.graduation.displayName == "升学")
        #expect(EventCategory.promotion.displayName == "升职")
        #expect(EventCategory.springFestival.displayName == "春节")
        #expect(EventCategory.midAutumn.displayName == "中秋")
        #expect(EventCategory.dragonBoat.displayName == "端午")
        #expect(EventCategory.other.displayName == "其他")
    }

    @Test func icons() {
        #expect(EventCategory.wedding.icon == "heart.fill")
        #expect(EventCategory.birthday.icon == "gift.fill")
        #expect(EventCategory.funeral.icon == "leaf.fill")
        #expect(EventCategory.other.icon == "ellipsis.circle.fill")
    }

    @Test func initFromRawValue() {
        #expect(EventCategory(rawValue: "wedding") == .wedding)
        #expect(EventCategory(rawValue: "invalid") == nil)
    }
}

// MARK: - GiftDirection Tests

struct GiftDirectionTests {

    @Test func allCasesCount() {
        #expect(GiftDirection.allCases.count == 2)
    }

    @Test func rawValues() {
        #expect(GiftDirection.sent.rawValue == "sent")
        #expect(GiftDirection.received.rawValue == "received")
    }

    @Test func displayNames() {
        #expect(GiftDirection.sent.displayName == "送出")
        #expect(GiftDirection.received.displayName == "收到")
    }

    @Test func icons() {
        #expect(GiftDirection.sent.icon == "arrow.up.circle.fill")
        #expect(GiftDirection.received.icon == "arrow.down.circle.fill")
    }

    @Test func initFromRawValue() {
        #expect(GiftDirection(rawValue: "sent") == .sent)
        #expect(GiftDirection(rawValue: "received") == .received)
        #expect(GiftDirection(rawValue: "unknown") == nil)
    }
}

// MARK: - RecordType Tests

struct RecordTypeTests {

    @Test func allCasesCount() {
        #expect(RecordType.allCases.count == 2)
    }

    @Test func rawValues() {
        #expect(RecordType.gift.rawValue == "gift")
        #expect(RecordType.loan.rawValue == "loan")
    }

    @Test func displayNames() {
        #expect(RecordType.gift.displayName == "随礼")
        #expect(RecordType.loan.displayName == "借贷")
    }

    @Test func icons() {
        #expect(RecordType.gift.icon == "gift.fill")
        #expect(RecordType.loan.icon == "banknote.fill")
    }

    @Test func initFromRawValue() {
        #expect(RecordType(rawValue: "gift") == .gift)
        #expect(RecordType(rawValue: "loan") == .loan)
        #expect(RecordType(rawValue: "invalid") == nil)
    }
}

// MARK: - RelationType Tests

struct RelationTypeTests {

    @Test func allCasesCount() {
        #expect(RelationType.allCases.count == 7)
    }

    @Test func rawValues() {
        #expect(RelationType.family.rawValue == "family")
        #expect(RelationType.colleague.rawValue == "colleague")
        #expect(RelationType.classmate.rawValue == "classmate")
        #expect(RelationType.friend.rawValue == "friend")
        #expect(RelationType.neighbor.rawValue == "neighbor")
        #expect(RelationType.business.rawValue == "business")
        #expect(RelationType.other.rawValue == "other")
    }

    @Test func displayNames() {
        #expect(RelationType.family.displayName == "亲戚")
        #expect(RelationType.colleague.displayName == "同事")
        #expect(RelationType.classmate.displayName == "同学")
        #expect(RelationType.friend.displayName == "朋友")
        #expect(RelationType.neighbor.displayName == "邻居")
        #expect(RelationType.business.displayName == "商务")
        #expect(RelationType.other.displayName == "其他")
    }

    @Test func icons() {
        #expect(RelationType.family.icon == "figure.and.child.holdinghands")
        #expect(RelationType.colleague.icon == "briefcase.fill")
        #expect(RelationType.classmate.icon == "book.fill")
        #expect(RelationType.friend.icon == "person.2.fill")
        #expect(RelationType.neighbor.icon == "house.and.flag.fill")
        #expect(RelationType.business.icon == "building.2.fill")
        #expect(RelationType.other.icon == "person.fill.questionmark")
    }

    @Test func initFromRawValue() {
        #expect(RelationType(rawValue: "family") == .family)
        #expect(RelationType(rawValue: "invalid") == nil)
    }
}
