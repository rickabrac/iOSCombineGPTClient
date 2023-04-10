//
//  ChatStore.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import Foundation
import Combine
import SwiftUI

typealias ChatStoreType = Store<ChatState, ChatAction>

struct ChatState: State {
	var prompt: String = ""
	var stream: AsyncStream<String>?
	var response: String = ""
	var sharing: Bool = false
	var error: String = ""
	var showingError = false
}

enum ChatAction {
	case setPrompt(String)
	case setStream(AsyncStream<String>)
	case streamResponse(AsyncStream<String>, String) // StreamResponseAction
	case updateResponse(String)
	case endResponse
	case setSharing(Bool)
	case throwError(String)
	case presentError
	case clearError
}

class ChatStore {
	
	var store: ChatStoreType // = ChatStore.store
	var response: String?
	var stream: AsyncStream<String>?
	
	init(store: ChatStoreType = ChatStore.store) {
		self.store = store
	}
	
	static var apiKey: String {
		guard let apiKey = ProcessInfo.processInfo.environment["GPT3_API_KEY"] else {
			fatalError("GPT3_API_KEY must be defined in your build environment (\"Edit Scheme...\"")
		}
		if apiKey == "" {
			fatalError("You must assign a valid key to GPT3_API_KEY in your build environment (\"Edit Scheme...\"")
		}
		return apiKey
	}
	
	static var store: ChatStoreType {
		return ChatStoreType { currentState, action in
			var newState = currentState
			switch action {
			case .setPrompt(let prompt):
				newState.prompt = prompt
				newState.response = ""
			case .setStream(let stream):
				newState.stream = stream
				newState.error = ""
			case .updateResponse(let response):
				newState.response = response
			case .endResponse:
				newState.prompt = ""
				newState.stream = nil
			case .setSharing(let sharing):
				newState.sharing = sharing
			case .throwError(let error):
				newState.error = error
			case .presentError:
				if newState.showingError {
					return newState
				}
				newState.showingError = true
			case .clearError:
				if newState.showingError == false {
					return newState
				}
				newState.showingError = false
				newState.error = ""
			case .streamResponse(_, _):
				// see ChatStore.StreamResponseAction
				break
			}
			return newState
		} middleware: {
			StreamResponseAction()
		}
	}
	
	var showResponse: Bool {
		guard let _ = response else {
			return false
		}
		return true
	}

	var shareable: Bool {
		guard let _ = stream else {
			return false
		}
		return true
	}
	
	//  MARK: ChatStore.StreamResponseAction

	private class StreamResponseAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .streamResponse(stream, response) = action else {
				return action
			}
			var updatedResponse = response
			let mutex = NSLock()
			mutex.lock()
			for try await fragment in stream {
				updatedResponse += fragment
				mutex.unlock()
				return .updateResponse(updatedResponse)
			}
			mutex.unlock()
			return .endResponse
		}
	}
}


