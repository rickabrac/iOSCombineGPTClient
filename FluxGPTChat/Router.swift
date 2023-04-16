//
//  Router.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import UIKit
import Combine

class Router: ObservableObject {
	var window: UIWindow
	var parent: Router?
	var path: String
	var store: RouterStoreType
	var child: [String : Router] = [:]
	var view: [String : UIViewController] = [:]
	var cancellables = Set<AnyCancellable>()
	var mySignals = Set<RouterSignal>()
	private var updates = 0
	
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		self.window = window
		self.parent = parent
		self.path = path
		self.store = store
		Task {
			await parent?.store.bindStateObserver(route, cancellables: &cancellables)
			await store.bindStateObserver(route, cancellables: &cancellables)
		}
	}
	
	func registerMySignal(_ signal: RouterSignal) {
		mySignals.insert(signal)
	}
	
	func start() {
		fatalError("Router.start: unimplemented by subclass")
	}
	
	func handleSignal(_ signal: String) async {
		await parent?.store.dispatch(action: .signal(signal))	// forward upstream
	}
	
	func handleMessage(_ message: String) async {
		await store.dispatch(action: .setMessage(message))	// forward downstream
	}
	
//	func getMySignalsArray() -> [String] {
//		fatalError("Router.getSignals: unimplemented by subclass")
//	}
	
	func route() {
		Task {
			// handle new route
			if await store.state.next.count > 0 {
await print("\(store.state.next.count)")
				let next = await store.state.next
				if next == path {
					fatalError("MainRouter.route: route to self \(next)")
				}
				let nextParts = next.components(separatedBy: "/")
				guard let module = nextParts.last else {
					fatalError("MainRouter.route: missing module \(next)")
				}
print("module=[\(module)]")
				if module.count > 0 {
					guard let child = child[module] else {
						fatalError("MainRouter.route: missing route \(next)")

					}
					await store.dispatch(action: .setNext(""))
					await child.store.dispatch(action: .setPath(next))
					child.start()
					return
				}
			}
			// handle downstream signal
			if let signal = await store.state.signal, await store.state.message == nil, await parent?.store.state.signal == nil {
				// downstream signal
				await handleSignal(signal)
				return
			}
			if let message = await parent?.store.state.message, await store.state.message == nil {
				// upstream message
				await handleMessage(message)
				return
			}
			if await store.state.signal == nil,
			   await store.state.message != nil,
			   let signal = await parent?.store.state.signal,
			   mySignals.contains(signal) == false {
				await parent?.store.dispatch(action: .clearSignal)
				await parent?.store.dispatch(action: .clearMessage)
				await store.dispatch(action: .clearMessage)
			}
			self.updates += 1
		}
	}
}

typealias RouterSignal = String
typealias RouterMessage = String

struct RouterState: State {
	var path = ""
	var next = ""
	var signal: RouterSignal? = nil
	var message: RouterSignal? = nil
}

enum RouterAction {
	case setPath(_ path: String)
	case setNext(_ path: String)
	case signal(_ event: RouterSignal)
	case clearSignal
	case setMessage(_ message: String)
	case clearMessage
}

typealias RouterStoreType = Store<RouterState, RouterAction>

func newRouterStore() -> RouterStoreType {
	return RouterStoreType { currentState, action in
		var newState = currentState
		switch action {
		case .setPath(let path):
			newState.path = path
		case .setNext(let next):
			newState.next = next
		case .signal(let event):
			if event != currentState.signal {
				newState.signal = event
			}
		case .clearSignal:
			newState.signal = nil
		case .setMessage(let message):
			newState.message = message
		case .clearMessage:
			newState.message = nil
		}
		return newState
	}
}
