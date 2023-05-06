//
//  AppDelegate.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	let window = UIWindow()
	
//	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//		if let scheme = url.scheme,
//		   scheme.caseInsensitiveCompare("CombineGPTClientShare") == .orderedSame,
//		   let page = url.host {
//			var parameters: [String: String] = [:]
//			URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
//				parameters[$0.name] = $0.value
//			}
////			print("redirect(to: \(page), with: \(parameters))")
//		}
//		return true
//	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let router = AppRouter(window, path: "/")
		router.start()
		if let _ = UserDefaults(suiteName: "group.gptclient")?.object(forKey: "imageData") {
			Task {
				await router.store.dispatch(action: .setName("image"))
			}
			return true
		}
		Task {
			await router.store.dispatch(action: .setName("main"))
		}
		return true
	}
}
