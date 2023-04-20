//
//  ChatRouter.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  This subclass of Router coordinates SplashUIView and ChatTabUIView.

import SwiftUI
import Combine

class ChatRouter: Router {
	
	private var chatTabUIViewController = UIViewController()
	static var instance: ChatRouter?

	required init(_ window: UIWindow, path: String, parent: Router?, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		guard let _ = parent else {
			fatalError("ChatRouter.init: parent missing")
		}
		if let module = path.components(separatedBy: "/").last, module != "chat" {
			fatalError("ChatRouter.init: wrong module (\(module)")
		}
		addSignalHandler("getAPIKey", upstream: nil,
			downstream: { (signal, response) in
				guard let apiKey = response?.components(separatedBy: ":").last else {
					fatalError("ChatRouter.upstream: failed to unwrap apiKey response")
				}
				UserDefaults.standard.set(apiKey, forKey: ChatGPTAPI.apiKeyDefaultsName)
				self.start()
			}
		)
		ChatRouter.instance = self
	}
	
	override func start() {
		DispatchQueue.main.async {
			self.chatTabUIViewController = UIHostingController(rootView: ChatTabUIView(router: self))
			self.window.rootViewController = self.chatTabUIViewController
			self.window.makeKeyAndVisible()
		}
	}
}
