//
//  Flower_Raising_GameApp.swift
//  Flower Raising Game
//
//  Created by miyamotokenshin on R 8/05/13.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        LocalNotificationService.shared.configure()
        MobileAds.shared.start()
        return true
    }
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
