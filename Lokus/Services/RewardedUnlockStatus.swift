// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import Foundation

/// Ödüllü reklam ile açılan geçici erişim.
enum RewardedUnlockStatus {
    static var remainingSeconds: TimeInterval? {
        let stored = UserDefaults.standard.double(forKey: Constants.lastUnlockTimestampKey)
        guard stored > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(Date(timeIntervalSince1970: stored))
        let total = Constants.unlockDurationHours * 3600
        let remaining = total - elapsed
        return remaining > 0 ? remaining : nil
    }

    static var isActive: Bool {
        remainingSeconds != nil
    }

    static var formattedRemaining: String? {
        guard let seconds = remainingSeconds else { return nil }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        }
        return "\(max(minutes, 1)) dk"
    }
}
