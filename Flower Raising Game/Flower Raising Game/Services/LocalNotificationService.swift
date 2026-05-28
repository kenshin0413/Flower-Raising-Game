import Foundation
import UserNotifications

/// アプリ内のローカル通知を管理するServiceです。
/// 花の状態に合わせて、次に届く通知文を毎回更新します。
final class LocalNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let dailyCareReminderIdentifier = "dailyCareReminder"
    private let urgentCareReminderIdentifier = "urgentCareReminder"

    private override init() {
        super.init()
    }

    /// アプリ起動時に呼び出して、通知の表示設定と許可確認を準備します。
    func configure() {
        center.delegate = self
        requestAuthorizationIfNeeded()
    }

    /// 花の状態に合わせて、次回以降の通知を予約し直します。
    func scheduleReminders(
        for flower: FlowerState,
        stressPercent: Double,
        deathRiskPercent: Double,
        isWilted: Bool,
        isDead: Bool,
        canWaterToday: Bool,
        canGiveSunlightToday: Bool,
        canFeedToday: Bool
    ) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else {
                return
            }

            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert]) { granted, _ in
                    guard granted else {
                        return
                    }

                    self.scheduleCurrentReminders(
                        for: flower,
                        stressPercent: stressPercent,
                        deathRiskPercent: deathRiskPercent,
                        isWilted: isWilted,
                        isDead: isDead,
                        canWaterToday: canWaterToday,
                        canGiveSunlightToday: canGiveSunlightToday,
                        canFeedToday: canFeedToday
                    )
                }
            case .authorized, .provisional, .ephemeral:
                self.scheduleCurrentReminders(
                    for: flower,
                    stressPercent: stressPercent,
                    deathRiskPercent: deathRiskPercent,
                    isWilted: isWilted,
                    isDead: isDead,
                    canWaterToday: canWaterToday,
                    canGiveSunlightToday: canGiveSunlightToday,
                    canFeedToday: canFeedToday
                )
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    /// ユーザーに通知許可を求めます。
    /// バナー表示に必要なalertだけを要求し、音やバッジは使いません。
    private func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else {
                return
            }

            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert]) { _, _ in }
            case .authorized, .provisional, .ephemeral:
                break
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    private func scheduleCurrentReminders(
        for flower: FlowerState,
        stressPercent: Double,
        deathRiskPercent: Double,
        isWilted: Bool,
        isDead: Bool,
        canWaterToday: Bool,
        canGiveSunlightToday: Bool,
        canFeedToday: Bool
    ) {
        center.removePendingNotificationRequests(
            withIdentifiers: [
                dailyCareReminderIdentifier,
                urgentCareReminderIdentifier
            ]
        )

        scheduleDailyCareReminder(
            message: dailyReminderMessage(
                for: flower,
                stressPercent: stressPercent,
                deathRiskPercent: deathRiskPercent,
                isWilted: isWilted,
                isDead: isDead,
                canWaterToday: canWaterToday,
                canGiveSunlightToday: canGiveSunlightToday,
                canFeedToday: canFeedToday
            )
        )

        guard isWilted || deathRiskPercent >= 70 || stressPercent >= 80 else {
            return
        }

        scheduleUrgentCareReminder(
            message: urgentReminderMessage(
                for: flower,
                deathRiskPercent: deathRiskPercent,
                isWilted: isWilted,
                isDead: isDead
            )
        )
    }

    /// 毎日20時に、その時点で予約された内容の通知を届けます。
    private func scheduleDailyCareReminder(message: NotificationMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyCareReminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// しおれ・枯れリスクが高い時だけ、翌朝9時にも強めの通知を出します。
    private func scheduleUrgentCareReminder(message: NotificationMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: urgentCareReminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func dailyReminderMessage(
        for flower: FlowerState,
        stressPercent: Double,
        deathRiskPercent: Double,
        isWilted: Bool,
        isDead: Bool,
        canWaterToday: Bool,
        canGiveSunlightToday: Bool,
        canFeedToday: Bool
    ) -> NotificationMessage {
        if isDead {
            return NotificationMessage(
                title: "花が枯れてしまいました",
                body: "植え替えをすると、新しい花を最初から育て直せます。"
            )
        }

        if isWilted || deathRiskPercent >= 70 {
            return NotificationMessage(
                title: "花がしおれています",
                body: mostImportantCareMessage(for: flower, fallback: "今の状態がかなり悪くなっています。早めに水分・日光・栄養を整えましょう。")
            )
        }

        if stressPercent >= 55 || deathRiskPercent >= 45 {
            return NotificationMessage(
                title: "花が少し疲れています",
                body: mostImportantCareMessage(for: flower, fallback: "ストレスが高くなっています。今日のお世話で状態を整えましょう。")
            )
        }

        if canWaterToday || canGiveSunlightToday || canFeedToday {
            let actions = pendingActionText(
                canWaterToday: canWaterToday,
                canGiveSunlightToday: canGiveSunlightToday,
                canFeedToday: canFeedToday
            )

            return NotificationMessage(
                title: "今日のお世話をしましょう",
                body: "\(actions)を整えると、花が少しずつ成長します。"
            )
        }

        return NotificationMessage(
            title: "今日のお世話は完了しています",
            body: "明日も花の様子を見て、ゆっくり育てていきましょう。"
        )
    }

    private func urgentReminderMessage(
        for flower: FlowerState,
        deathRiskPercent: Double,
        isWilted: Bool,
        isDead: Bool
    ) -> NotificationMessage {
        if isDead {
            return NotificationMessage(
                title: "植え替えできます",
                body: "花は枯れてしまいました。植え替えで新しい育成を始められます。"
            )
        }

        if deathRiskPercent >= 85 {
            return NotificationMessage(
                title: "枯れリスクがかなり高いです",
                body: mostImportantCareMessage(for: flower, fallback: "このまま放置すると危険です。早めに状態を確認しましょう。")
            )
        }

        if isWilted {
            return NotificationMessage(
                title: "花がしおれています",
                body: mostImportantCareMessage(for: flower, fallback: "しおれ状態が続くと枯れやすくなります。今日中に様子を見てあげましょう。")
            )
        }

        return NotificationMessage(
            title: "花のストレスが高めです",
            body: mostImportantCareMessage(for: flower, fallback: "状態が崩れ始めています。早めにお世話しましょう。")
        )
    }

    private func mostImportantCareMessage(for flower: FlowerState, fallback: String) -> String {
        if flower.water <= 18 {
            return "水分がかなり不足しています。水やりをしないと、しおれやすくなります。"
        }

        if flower.water >= 96 {
            return "水が多すぎるかもしれません。根腐れしないように、今日は日光を意識しましょう。"
        }

        if flower.nutrition <= 22 {
            return "栄養がかなり不足しています。肥料をあげると回復しやすくなります。"
        }

        if flower.nutrition >= 96 {
            return "肥料が多すぎるかもしれません。肥料焼けに注意して、少し様子を見ましょう。"
        }

        if flower.sunlight <= 22 {
            return "日光が足りていません。日光をあげると成長しやすくなります。"
        }

        if flower.sunlight >= 96 {
            return "日光が強すぎる状態です。水分が減りやすいので様子を見てあげましょう。"
        }

        if flower.mood <= 30 {
            return "ストレスがかなり高くなっています。今日のお世話で落ち着かせてあげましょう。"
        }

        return fallback
    }

    private func pendingActionText(
        canWaterToday: Bool,
        canGiveSunlightToday: Bool,
        canFeedToday: Bool
    ) -> String {
        var actions: [String] = []

        if canWaterToday {
            actions.append("水分")
        }

        if canGiveSunlightToday {
            actions.append("日光")
        }

        if canFeedToday {
            actions.append("栄養")
        }

        return actions.joined(separator: "・")
    }

    /// アプリを開いている最中に通知時間が来た場合も、バナーとして表示します。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
}

private struct NotificationMessage {
    let title: String
    let body: String
}
