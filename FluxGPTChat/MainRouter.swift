//
//  MainRouter.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI
import Combine

class MainRouter: Router {
	private var splashUIViewController: UIViewController? = nil
	
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		super.init(window, path: path, parent: parent, store: store)
		if parent != nil {
			fatalError("MainRouter.init: parent should be nil")
		}
		if path != "/" {
			fatalError("MainRouter.init: path should be \"/\"")
		}
		child["chat"] = ChatRouter(window, path: "/chat", parent: self)
		Task {
			await store.bindStateObserver(route, cancellables: &cancellables)
		}
		registerMySignal("getAPIKey")
	}
	
	override func start() {
		DispatchQueue.main.async {
			let splashUIView = SplashUIView(router: self)
			self.splashUIViewController = UIHostingController(rootView: splashUIView)
			self.window.rootViewController = self.splashUIViewController
			self.window.makeKeyAndVisible()
			self.splashUIViewController?.dismiss(animated: true)
			DispatchQueue.global(qos: .userInitiated).async { // [weak self] in
				sleep(3)
				Task {
					await self.store.dispatch(action: .setNext("/chat"))
				}
			}
		}
	}
	
	override func handleSignal(_ signal: String) async {
		if mySignals.contains(signal) == false {
			await super.handleSignal(signal)
			return
		}
		await store.dispatch(action: .signal(signal))
		switch signal {
		case "getAPIKey":
			guard let apiKey = ProcessInfo.processInfo.environment["GPT3_API_KEY"] else {
				fatalError("You must assign a valid GPT3 API key to GPT3_API_KEY in your Xcode environment (under Product > Scheme > Edit Scheme...)")
			}
			await store.dispatch(action: .setMessage("apiKey:\(apiKey)"))
		default:
			fatalError("MainRouter.handleSignal: unhandled signal \"\(signal)\"")
		}
	}
	
	override func handleMessage(_ message: String) async {
		return
	}
}
