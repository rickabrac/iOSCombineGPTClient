//
//  ChatRouter.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI
import Combine

class ChatRouter: Router {
	var window: UIWindow
	var parent: Router?
	var path: String
	var store: RouterStoreType
	var child: [String : Router] = [:]
	var view: [String : UIViewController] = [:]
	var cancellables = Set<AnyCancellable>()
	let chatTabViewController: UIViewController
	
	required init(_ window: UIWindow, path: String, parent: Router?, store: RouterStoreType = newRouterStore()) {
		self.window = window
		self.path = path
		self.parent = parent
		self.store = store
		guard let parent = parent else {
			fatalError("ChatRouter.init: parent missing")
		}
		if let module = path.components(separatedBy: "/").last, module != "chat" {
			fatalError("ChatRouter.init: wrong module (\(module)")
		}
		self.chatTabViewController = UIHostingController(rootView: ChatTabUIView(router: store))
		Task {
			await parent.store.bindStateObserver(route, cancellables: &cancellables)
			await store.bindStateObserver(route, cancellables: &cancellables)
		}
	}
	
	func start() {
		DispatchQueue.main.async {
			self.window.rootViewController = self.chatTabViewController
			self.window.makeKeyAndVisible()
		}
	}
	
	func route() {
		Task {
			if await store.state.next.count > 0 {
				// new route
				let next = await store.state.next
				if next == path {
					fatalError("ChatRouter.route: route to self \(next)")
				}
				let nextParts = next.components(separatedBy: "/")
				guard let module = nextParts.last else {
					fatalError("ChatRouter.route: missing module \(next)")
				}
				// clear current path
				await store.dispatch(action: .setNext(""))
				guard let child = child[module] else {
					// propogate to parent
					await parent?.store.dispatch(action: .setPath(next))
					return
				}
				// route to child
				await child.store.dispatch(action: .setPath(next))
				child.start()
				return
			}
			if let signal = await store.state.signal, await store.state.message == nil, await parent?.store.state.signal == nil {
				// downstream signal
				await parent?.store.dispatch(action: .signal(signal))
				return
			}
			if let message = await parent?.store.state.message, await store.state.message == nil {
				// upstream message
				let parts = message.components(separatedBy: ":")
				guard parts.first == "apiKey", parts.count == 2, let _ = parts.last else {
					fatalError("ChatRouter.route: unknown message (\(message)")
				}
				await store.dispatch(action: .setMessage(message))
				return
			}
			if await store.state.signal == nil, await store.state.message != nil, await parent?.store.state.signal == "getAPIKey" {
				await parent?.store.dispatch(action: .clearSignal)
				await parent?.store.dispatch(action: .clearMessage)
				await store.dispatch(action: .clearMessage)
			}
		}
	}
}
