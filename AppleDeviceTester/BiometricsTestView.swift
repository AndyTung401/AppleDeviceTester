//
//  FaceIDTestView.swift
//  AppleDeviceTester
//
//  Created by 董承威 on 2025/9/28.
//

import SwiftUI
import LocalAuthentication

struct BiometricsTestView: View {
    @State private var isUnlocked = false
    @State private var authMessage: String?
    @State private var biometryType: LABiometryType = .none
    @State private var isAuthenticating = false

    private let reason = "To test BioMetrics authentication"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isUnlocked ? .green : .red)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))

            Text(isUnlocked ? "Unlocked" : "Locked")
                .font(.largeTitle)
                .foregroundColor(isUnlocked ? .green : .red)

            if let authMessage {
                Text(authMessage)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if biometryType != .none {
                Text(biometryTypeLabel(biometryType))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Button {
                authenticate()
            } label: {
                if isAuthenticating {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Text("Unlock")
                        .bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
        }
        .padding()
    }

    private func authenticate() {
        isAuthenticating = true
        authMessage = nil

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passwords"

        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication // 支持密码回退

        // 先检查是否可评估（包含密码/生物识别）
        if context.canEvaluatePolicy(policy, error: &error) {
            biometryType = context.biometryType
            context.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        isUnlocked = true
                        authMessage = nil
                        print("Authentication successful")
                    } else {
                        isUnlocked = false
                        authMessage = mapLAError(evalError)
                        print("Authentication failed: \(authMessage ?? "Unknown error")")
                    }
                }
            }
        } else {
            // 无法评估：可能未设置设备密码或策略不可用
            DispatchQueue.main.async {
                isAuthenticating = false
                isUnlocked = false
                biometryType = context.biometryType
                authMessage = error?.localizedDescription ?? "Device not equipped with FaceID/TouchID."
                print("Cannot evaluate policy: \(authMessage ?? "")")
            }
        }
    }

    private func mapLAError(_ error: Error?) -> String {
        guard let nsError = error as NSError? else { return "Authenticate failed." }
        let code = LAError(_nsError: nsError).code
        switch code {
        case .authenticationFailed:   return "Authentication failed. Please try again."
        case .userCancel:             return "Cancelled by user"
        case .userFallback:           return "Choose password instead"
        case .systemCancel:           return "Cancelled by system. Try again later."
        case .passcodeNotSet:         return "This device does not have a passcode."
        case .biometryNotAvailable:   return "This device does not have a biometric ID"
        case .biometryNotEnrolled:    return "BioMetrics not enrolled. Please enroll in Settings."
        case .biometryLockout:        return "BioMetrics are locked out. Try again later."
        default:
            return nsError.localizedDescription
        }
    }

    private func biometryTypeLabel(_ type: LABiometryType) -> String {
        switch type {
        case .touchID: return "Support Touch ID"
        case .faceID:  return "Support Face ID"
        default:       return ""
        }
    }
}
