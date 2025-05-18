//
//  AppDelegate.swift
//  BlueBox
//
//  Created by Алексей Козачук on 11.05.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let tabBarController = UITabBarController()
        
        let generatorVC = GeneratorVC()
        generatorVC.tabBarItem = UITabBarItem(title: "Generate", image: UIImage(systemName: "megaphone"), tag: 0)
        
        let recognizerVC = RecognizerVC()
        recognizerVC.tabBarItem = UITabBarItem(title: "Recognize", image: UIImage(systemName: "ear.badge.waveform"), tag: 1)
        
        tabBarController.viewControllers = [generatorVC, recognizerVC]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        window?.overrideUserInterfaceStyle = .light
        return true
    }
}
