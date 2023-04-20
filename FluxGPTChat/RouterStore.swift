//
//  RouterStore.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Router/coordinator state-machine

import Foundation

struct RouterState: State {
	var name = ""
	var path = ""
	var next = ""
	var signal: String? = nil
	var response: String? = nil
	var updated: TimeInterval = 0
}

enum RouterAction {
	case setName(_ name: String)
	case setNext(_ path: String)
	case setPath(_ path: String)
	case signal(_ signal: String)
	case respond(_ response: String)
	case clearSignal
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
		}
		newState.updated = NSDate().timeIntervalSince1970
		return newState
	}
}
