//
//  Router.swift
//  CombineGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  State-driven app router base class. AppRouter and ChatRouter are derived instances.
//  Routers function in lieu of traditional coordinators in my architecture.

import UIKit
import Combine

class Router: ObservableObject {
	
	var window: UIWindow
	var parent: Router?
	var store: RouterStoreType
	var routers: [String : Router] = [:]
	var viewControllers: [String : UIViewController] = [:]
	private var handlers: [String : RouterSignalHandlers] = [:]
	private var path: String
	private var updated: TimeInterval = 0
	private var pool = Set<AnyCancellable>()
	
	/// <#Initializer#>
	///
	/// - Parameters:
	///     - window: UIWindow used to display all views
	///     - path:  absolute path of most recently active route (e.g. "/chat/settings", "/chat", "/getGPTKey")
	///     - parent:  parent Router subclass instance
	///     - store: Router subclass instance state machine
	///
	required init(_ window: UIWindow, path: String, parent: Router? = nil, store: RouterStoreType = newRouterStore()) {
		self.window = window
		self.path = path
		self.parent = parent
		self.store = store
		Task {
			await parent?.store.bindStateObserver(route, &pool)
			await store.bindStateObserver(route, &pool)
		}
	}
	
	/// <#Function signature router signal handlers#>
	///
	typealias SignalHandler = ((String, String?) async -> Void)
	
	private class RouterSignalHandlers {
		let upstream: SignalHandler?
		let downstream: SignalHandler?
		init(upstream: SignalHandler?, downstream: SignalHandler?) {
			self.upstream = upstream
			self.downstream = downstream
		}
	}
	
	/// <#Register a routing event and RouteSignalHandler for this instance#>
	///
	/// - Parameters:
	///     - signal: unique identifier of relative path
	///     - upstream: response handler for upstream requests
	///     - downstream: signal handler for downstream responses
	///
	func addSignalHandler( _ signal: String,
	   upstream: SignalHandler?,
	   downstream: SignalHandler?) {
		handlers[signal] = RouterSignalHandlers(upstream: upstream, downstream: downstream)
	}
	
	/// <#Start or restart the router#>
	///
	func start() {
		fatalError("Router.start: unimplemented by subclass")
	}
	
	/// <#Set viewController of view window#>
	///
	/// - Parameters:
	///     - vc: view controller to be assign to active 
	///
	private func setWindowViewController(_ vc: UIViewController) {
		window.rootViewController = vc
	}
	
	/// <#Respond to a new route or RouterSignal#>
	///
	/// - Parameters:
	///     - vc: view controller to be assign to active
	///
	private func route() {
		Task {
			defer {
				self.updated = NSDate().timeIntervalSince1970
			}
			// new route?
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
						guard let child = viewControllers[module] else {
							fatalError("Router.route: missing route \(next)")
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
					await upstream(signal, nil)
					return
				}
				// if no handler, forward upstream
				await parent?.store.dispatch(action: .signal(signal))
				return
			}
			// downstream signal?
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
