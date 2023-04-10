//
//  AppCoordinator.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import UIKit
import SwiftUI

class AppCoordinator: Coordinator {
	let window: UIWindow
	var startNC: UINavigationController? = nil
	var startVC: UIViewController? = nil
  
	init(window: UIWindow) {
		self.window = window
		startVC = UIHostingController(rootView: RootUIView())
		startVC?.navigationItem.title = "GPT3 Chat (SwiftUI)"
	}
  
	func start() {
		defer { window.makeKeyAndVisible() }
		guard let _ = startVC else {
			guard let _ = startNC else {
				fatalError("NO START VC OR NC")
			}
			window.rootViewController = startNC
			window.makeKeyAndVisible()
			return
		}
		window.rootViewController = startVC
		window.makeKeyAndVisible()
	}
}
