//
//  Flower_Raising_GameApp.swift
//  Flower Raising Game
//
//  Created by miyamotokenshin on R 8/05/13.
//

import SwiftUI
import FirebaseAnalytics
import FirebaseCore
import GoogleMobileAds
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseApp.app()?.isDataCollectionDefaultEnabled = true
        Analytics.setAnalyticsCollectionEnabled(true)
        LocalNotificationService.shared.configure()
        return true
    }
}

@MainActor
func startDeferredAppServices() {
    // 広告SDKは内部でWebKitプロセスを立ち上げるため、コールドスタート中に実行すると
    // Widget経由の起動がLaunch Screenで止まったように見えます。最初の画面を出してから開始します。
    MobileAds.shared.start()
    WidgetCenter.shared.reloadAllTimelines()
}

@main
struct Flower_Raising_GameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashRootView()
        }
    }
}
