//
//  MainRouter.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import UIKit
import Combine

class MainRouter: Router {
	var window: UIWindow
	var parent: Router?
	var path: String
	var store: RouterStoreType
	var child: [String : Router] = [:]
	var view: [String : UIViewController] = [:]
	var cancellables = Set<AnyCancellable>()
	
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		self.window = window
		self.parent = parent
		self.path = path
		if parent != nil {
			fatalError("MainRouter.init: parent should be nil")
		}
		if path != "/" {
			fatalError("MainRouter.init: path should be \"/\"")
		}
		self.store = store
		child["chat"] = ChatRouter(window, path: "/chat", parent: self)
		Task {
			await store.bindStateObserver(route, cancellables: &cancellables)
		}
	}
	
	func start() {
		Task {
			await store.dispatch(action: .setNext("/chat"))
		}
	}
	
	func route() {
		Task {
			// handle new route
			if await store.state.next.count > 0 {
				let next = await store.state.next
				if next == path {
					fatalError("MainRouter.route: route to self \(next)")
				}
				let nextParts = next.components(separatedBy: "/")
				guard let module = nextParts.last else {
					fatalError("MainRouter.route: missing module \(next)")
				}
				guard let child = child[module] else {
					fatalError("MainRouter.route: missing route \(next)")

				}
				await store.dispatch(action: .setNext(""))
				await child.store.dispatch(action: .setPath(next))
				child.start()
				return
			}
			// handle downstream signal
			if let signal = await store.state.signal, await store.state.message == nil {
				if signal != "getAPIKey" {
					print("MainRouter: unknown signal")
					await store.dispatch(action: .clearSignal)
					return
				}
				await store.dispatch(action: .signal(signal))
				guard let apiKey = ProcessInfo.processInfo.environment["GPT3_API_KEY"] else {
					fatalError("You must assign a valid GPT3 API key to GPT3_API_KEY in your Xcode environment (under Product > Scheme > Edit Scheme...)")
				}
				await store.dispatch(action: .setMessage("apiKey:\(apiKey)"))
			}
		}
	}
}
