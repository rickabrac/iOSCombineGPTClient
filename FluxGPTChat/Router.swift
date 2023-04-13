//
//  Router.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI
import Combine

protocol Router {
	var window: UIWindow { get }
	var parent: Router? { get }
	var store: RouterStoreType { get }
	var child: [String : Router] { get }
	var view: [String : UIViewController] { get }
	var cancellables: Set<AnyCancellable>{ get }
	init(_ window: UIWindow, path: String, parent: Router?, store: RouterStoreType)
	func start()
	func route()
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
