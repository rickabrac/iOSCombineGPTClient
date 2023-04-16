//
//  AppDelegate.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	let window = UIWindow()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let router = MainRouter(window, path: "/")
		router.start()
		return true
	}
}
