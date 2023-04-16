//
//  ChatRouter.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI
import Combine

class ChatRouter: Router {
	private var chatTabUIViewController = UIViewController()
	
	required init(_ window: UIWindow, path: String, parent: Router?, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		guard let _ = parent else {
			fatalError("ChatRouter.init: parent missing")
		}
		if let module = path.components(separatedBy: "/").last, module != "chat" {
			fatalError("ChatRouter.init: wrong module (\(module)")
		}
	}
	
	override func start() {
		DispatchQueue.main.async {
			self.chatTabUIViewController = UIHostingController(rootView: ChatTabUIView(router: self))
			self.window.rootViewController = self.chatTabUIViewController
			self.window.makeKeyAndVisible()
		}
	}
}
