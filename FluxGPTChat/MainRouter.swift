//
//  MainRouter.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  This Router subclass coordinates SplashUIView, ChatRouter and APIKeyUIView and is the app entry point.

import SwiftUI
import Combine

class MainRouter: Router {
	
	private var splashUIViewController: UIViewController? = nil
	static var instance: MainRouter?
	
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		assert(parent == nil, "MainRouter.init: parent should be nil")
		assert(path == "/", "MainRouter.init: path should be \"/\"")
		routers["chat"] = ChatRouter(window, path: "/chat", parent: self)
		viewControllers["getAPIKey"] = UIHostingController(rootView: APIKeyUIView(router: self, store: ChatStore.store))
		addSignalHandler("getAPIKey",
			upstream: { (_,_) in
				if let key = ChatGPTAPI.apiKey {
					await store.dispatch(action: .respond(key))
				} else if await store.state.path != "getAPIKey" {
					await store.dispatch(action: .setNext("/getAPIKey"))
				}
			},
			downstream: nil
		)
		Task {
			await routers["chat"]?.store.dispatch(action: .setName("chat"))
		}
		MainRouter.instance = self
	}
	
	override func start() {
		DispatchQueue.main.async {
			let splashUIView = SplashUIView(router: self)
			
			self.splashUIViewController = UIHostingController(rootView: splashUIView)
			
			self.window.rootViewController = self.splashUIViewController
			self.window.makeKeyAndVisible()
			
			DispatchQueue.global(qos: .userInitiated).async {
				sleep(2) // after a delay, route to chat interface
				DispatchQueue.main.async {
					self.splashUIViewController?.dismiss(animated: true)
				}
				Task {
					await self.store.dispatch(action: .setNext("/chat"))
				}
			}
		}
	}
}
