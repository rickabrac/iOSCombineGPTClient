//
//  AppRouter.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  App entry point and Router subclass that coordinates SplashView, ChatRouter and APIKeyView.

import SwiftUI
import Combine

class AppRouter: Router {
	
	private var splashViewController: UIViewController? = nil
	static var instance: AppRouter?
	
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		assert(parent == nil, "AppRouter.init: parent should be nil")
		assert(path == "/", "AppRouter.init: path should be \"/\"")
		routers["chat"] = ChatRouter(window, path: "/chat", parent: self)
		viewControllers["getGPTKey"] = UIHostingController(rootView: GetKeyView(router: self, store: ChatStore.store))
		addSignalHandler("getGPTKey",
			upstream: { (_,_) in
				if let key = ChatAPI.apiKey {
					await store.dispatch(action: .respond(key))
				} else if await store.state.path != "getGPTKey" {
					await store.dispatch(action: .setNext("/getGPTKey"))
				}
			},
			downstream: nil
		)
		Task {
			await routers["chat"]?.store.dispatch(action: .setName("chat"))
		}
		AppRouter.instance = self
	}
	
	override func start() {
		DispatchQueue.main.async {
			let splashView = SplashView(router: self)
			
			self.splashViewController = UIHostingController(rootView: splashView)
			
			self.window.rootViewController = self.splashViewController
			self.window.makeKeyAndVisible()
			
			DispatchQueue.global(qos: .userInitiated).async {
				sleep(3)
				// reroute to the chat interface after a few seconds
				DispatchQueue.main.async {
					self.splashViewController?.dismiss(animated: true)
				}
				Task {
					await self.store.dispatch(action: .setNext("/chat"))
				}
			}
		}
	}
}