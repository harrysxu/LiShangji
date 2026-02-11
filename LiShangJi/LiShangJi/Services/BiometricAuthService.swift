//
//  BiometricAuthService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import LocalAuthentication

/// 生物识别认证服务
class BiometricAuthService {
    static let shared = BiometricAuthService()
    private init() {}

    /// 生物识别类型
    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    /// 检查设备支持的生物识别类型
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    /// 检查设备是否支持生物识别
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// 执行生物识别认证
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "使用密码"
        context.localizedCancelTitle = "取消"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "解锁随手礼查看您的人情记录"
            )
        } catch {
            return false
        }
    }

    /// 生物识别名称
    var biometricName: String {
        switch biometricType() {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "生物识别"
        }
    }
}
