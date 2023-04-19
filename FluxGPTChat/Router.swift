//
//  Router.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import UIKit
import Combine

class Router: ObservableObject {
	var window: UIWindow
	var parent: Router?
	var store: RouterStoreType
	var routers: [String : Router] = [:]
	var views: [String : UIViewController] = [:]
	private var handlers: [String : RouteSignalHandler] = [:]
	private var path: String
	private var pool = Set<AnyCancellable>()
	private var updates = 0
	
	/// <#Initializer#>
	///
	/// - Parameters:
	///     - window: UIWindow of active view
	///     - path: relative path possibly including URL-style arguments (e.g. "?foo=bar
	///		- parent:  parent Router subclass instance
	///     - store: Router subclass instance state machine
	///
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		self.window = window
		self.parent = parent
		self.path = path
		self.store = store
		Task {
			await parent?.store.bindStateObserver(route, &pool)
			await store.bindStateObserver(route, &pool)
		}
	}
	
	/// <#Start router#>
	///
	func start() {
		fatalError("Router.start: unimplemented by subclass")
	}
	
	/// <#Register a routing event and RouteSignalHandler for this instance#>
	///
	/// - Parameters:
	///     - signal: unique identifier of relative path
	///     - upstream: response handler for upstream requests
	///     - downstream: signal handler for downstream responses
	///
	func addSignalHandler( _ signal: String,
	   upstream: ((String) async -> Void)?,
	   downstream: ((String, String) async -> Void)?) {
		handlers[signal] = RouteSignalHandler(upstream: upstream, downstream: downstream)
	}
	
	/// <#Set viewController of view window#>
	///
	/// - Parameters:
	///     - vc: view controller to be assign to active 
	///
	private func setWindowViewController(_ vc: UIViewController) {
		window.rootViewController = vc
	}
	
//	private var memaddr: String {
//		return "\(MemoryAddress(of: self).description)"
//	}
//	
	func route() {
		Task {
			// route request?
			defer { self.updates = 1 }
			if await store.state.next.count > 0 {
				let next = await store.state.next
				if next == path {
					fatalError("Router.route: route to self \(next)")
				}
				let nextParts = next.components(separatedBy: "/")
				guard let module = nextParts.last else {
					fatalError("Router.route: missing module \(next)")
				}
				if module.count > 0 {
					guard let newRouter = routers[module] else {
						guard let child = views[module] else {
							fatalError("Router.route: missing route \(next)")
						}
						if let _ = routers[module] {
							print("dismiss router?")
						} else if let _ = views[module] {
							print("dismiss view?")
						}
						await store.dispatch(action: .setPath(module))
						DispatchQueue.main.async {
							self.setWindowViewController(child)
							Task {
								self.window.makeKeyAndVisible()
							}
						}
						return
					}
					await store.dispatch(action: .setNext(""))
					await newRouter.store.dispatch(action: .setPath(next))
					newRouter.start()
				}
				return
			}
			// upstream signal?
			if let signal = await store.state.signal,
			   await store.state.response == nil,
			   await parent?.store.state.signal == nil {
				if let handler = handlers[signal], let upstream = handler.upstream {
					await upstream(signal)
					return
				}
				// if no handler, forward upstream
				await parent?.store.dispatch(action: .signal(signal))
				return
			}
			// downstream response?
			if let signal = await store.state.signal,
			   await store.state.response == nil,
			   let parentSignal = await parent?.store.state.signal,
			   let response = await parent?.store.state.response {
				assert(signal == parentSignal)
				await parent?.store.dispatch(action: .clearSignal)
				await store.dispatch(action: .respond(response))
				if let handler = handlers[signal], let downstream = handler.downstream {
					await downstream(signal, response)
				}
				return
			}
		}
	}
}

fileprivate class RouteSignalHandler {
	let upstream: ((String) async -> Void)?
	let downstream: ((String, String) async -> Void)?
	init(upstream: ((String) async -> Void)?, downstream: ((String, String) async -> Void)?) {
		self.upstream = upstream
		self.downstream = downstream
	}
}

struct RouterState: State {
	var name = ""
	var path = ""
	var next = ""
	var signal: String? = nil
	var response: String? = nil
}

enum RouterAction {
	case setName(_ name: String)
	case setNext(_ path: String)
	case setPath(_ path: String)
	case signal(_ signal: String)
	case respond(_ response: String)
	case clearSignal
	case clearMessage
}

typealias RouterStoreType = Store<RouterState, RouterAction>

func newRouterStore() -> RouterStoreType {
	return RouterStoreType { currentState, action in
		var newState = currentState
		switch action {
		case .setName(let name):
			newState.name = name
		case .setPath(let path):
			if path != currentState.path {
				newState.signal = nil
//				newState.response = nil
				newState.next = ""
				newState.path = path
			}
		case .setNext(let next):
			newState.next = next
			newState.signal = nil
		case .signal(let signal):
			if signal != currentState.signal {
				newState.signal = signal
			}
		case .clearSignal:
			newState.signal = nil
			newState.response = nil
		case .respond(let response):
			newState.response = response
		case .clearMessage:
			newState.response = nil
		}
		return newState
	}
}
