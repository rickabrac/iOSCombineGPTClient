//
//  ChatStore.swift
//  CombineGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Source of truth / state-machine for chat functionality

import Foundation
import SwiftUI

enum ChatAction {
	case setRouter(RouterStoreType)
	case setPrompt(String)
	case setStream(AsyncStream<String>?)
	case streamResponse(AsyncStream<String>, String)
	case updateResponse(String)
	case endResponse
	case setSharing(Bool)
	case throwError(String)
	case presentError
	case clearError
	case getGPTKey(RouterStoreType)
	case setTestAPIKey(String)
	case tryTestAPIKey(AsyncStream<String>, String)
	case setAPIKey(String)
	case setAPI(ChatAPIProtocol)
}

struct ChatState: State {
	var router: RouterStoreType?
	var prompt: String = ""
	var stream: AsyncStream<String>?
	var response: String = ""
	var isSharingResponse: Bool = false
	var error: String = ""
	var isShowingError = false
	var apiKey: String? = nil
	var testAPIKey: String = ""
	var api: ChatAPIProtocol? = nil
}

typealias ChatStoreType = Store<ChatState, ChatAction>

class ChatStore {
	
	var store: ChatStoreType
	var response: String?
	var stream: AsyncStream<String>?
	
	init(store: ChatStoreType = ChatStore.store) {
		self.store = store
	}
	
	static var store: ChatStoreType {
		return ChatStoreType { currentState, action in
			var newState = currentState
			switch action {
			case .setRouter(let router):
				newState.router = router
				break
			case .setPrompt(let prompt):
				newState.prompt = prompt
				newState.response = ""
			case .setStream(let stream):
				newState.stream = stream
				newState.error = ""
			case .streamResponse:
				// see ChatStore.StreamResponseAction
				break
			case .updateResponse(let response):
				newState.response = response
			case .endResponse:
				newState.prompt = ""
				newState.stream = nil
				print("\(newState.response)")
			case .setSharing(let sharing):
				newState.isSharingResponse = sharing
			case .throwError(let error):
				newState.error = error
			case .presentError:
				if newState.isShowingError {
					return newState
				}
				newState.isShowingError = true
			case .clearError:
				if newState.isShowingError == false {
					return newState
				}
				newState.isShowingError = false
				newState.error = ""
				break
			case .getGPTKey:
				// see ChatStore.getGPTKeyAction
				break
			case .setTestAPIKey(let testKey):
				newState.testAPIKey = testKey
				newState.stream = nil
			case .tryTestAPIKey:
				// see ChatStore.TryTestAPIKeyAction
				break
			case .setAPIKey(let key):
				newState.apiKey = key
				newState.stream = nil
				newState.error = ""
				break
			case .setAPI(let api):
				newState.api = api
			}
			return newState
		} middleware: {
			StreamResponseAction()
			getGPTKeyAction()
			TryTestAPIKeyAction()
		}
	}
	
	var showResponse: Bool {
		guard let _ = response else {
			return false
		}
		return true
	}

	var isShareable: Bool {
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
			for try await fragment in stream {
				updatedResponse += fragment
				return .updateResponse(updatedResponse)
			}
			return .endResponse
		}
	}
	
	//  MARK: ChatStore.getGPTKeyAction
	
	private class getGPTKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .getGPTKey(router) = action else {
				return action
			}
			if let key = ChatGPTAPI.apiKey {
				return .setAPIKey(key)
			} else if await router.state.response == nil {
				await router.dispatch(action: .signal("getGPTKey"))
			}
			return action
		}
	}
	
	//  MARK: ChatStore.TryTestAPIKeyAction

	private class TryTestAPIKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .tryTestAPIKey(stream, key) = action else {
				return action
			}
			for try await _ in stream {
				return .setAPIKey(key)
			}
			return .setTestAPIKey("")
		}
	}
}
