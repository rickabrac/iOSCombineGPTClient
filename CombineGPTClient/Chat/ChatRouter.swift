//
//  ChatRouter.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Router subclass that coordinates ChatTabView.

import SwiftUI
import Combine

class ChatRouter: Router {
	
	private var chatTabViewController = UIViewController()
	static var instance: ChatRouter?

	required init(_ window: UIWindow, path: String, parent: Router?, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		guard let _ = parent else {
			fatalError("ChatRouter.init: parent missing")
		}
		if let module = path.components(separatedBy: "/").last, module != "chat" {
			fatalError("ChatRouter.init: wrong module (\(module)")
		}
		addSignalHandler("getGPTKey", upstream: nil,
			downstream: { (signal, response) in
				guard let apiKey = response?.components(separatedBy: ":").last else {
					fatalError("ChatRouter.upstream: failed to unwrap apiKey response")
				}
				UserDefaults.standard.set(apiKey, forKey: ChatAPI.apiKeyDefaultsName)
				self.start()
			}
		)
		ChatRouter.instance = self
	}
	
	override func start() {
		DispatchQueue.main.async {
			self.chatTabViewController = UIHostingController(rootView: ChatTabView(router: self))
			self.window.rootViewController = self.chatTabViewController
			self.window.makeKeyAndVisible()
		}
	}
}
