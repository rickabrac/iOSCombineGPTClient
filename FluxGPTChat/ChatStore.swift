//
//  ChatStore.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import Foundation
import Combine
import SwiftUI

fileprivate let apiKeyDefaultsName = "GPT3_API_KEY"

enum ChatAction {
	case setRouter(RouterStoreType)
	case setPrompt(String)
	case setStream(AsyncStream<String>?)
	case streamResponse(AsyncStream<String>, String) // StreamResponseAction
	case updateResponse(String)
	case endResponse
	case setSharing(Bool)
	case throwError(String)
	case presentError
	case clearError
	case getAPIKey(RouterStoreType)
	case setAPIKey(String)
	case clearAPIKey
	case setAPI(ChatGPTAPI)
	case promptAPIKey
	case checkAPIKey(String, ChatStoreType)
	case setTestAPIKey(String)
	case verifyStream(AsyncStream<String>, String)
	case saveAPIKey(String)
}

struct ChatState: State {
	var router: RouterStoreType?
	var prompt: String = ""
	var stream: AsyncStream<String>?
	var response: String = ""
	var sharing: Bool = false
	var error: String = ""
	var showingError = false
	var apiKey: String? = nil
	var api: ChatGPTAPI? = nil
	var testAPIKey: String = ""
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
			case .streamResponse:
				// see ChatStore.StreamResponseAction
				break
			case .getAPIKey:
				// see ChatStore.GetAPIKeyAction
				break
			case .setAPI(let api):
				newState.api = api
			case .promptAPIKey:
				// see ChatStore.promptAPIKeyAction
				break;
			case .setAPIKey(let key):
				newState.apiKey = key
				newState.stream = nil
				newState.error = ""
			case .clearAPIKey:
				newState.apiKey = nil
			case .checkAPIKey:
				// see ChatStore.CheckAPIKeyAction
				break
			case .setTestAPIKey(let testKey):
				newState.testAPIKey = testKey
				newState.stream = nil
				newState.error = ""
			case .verifyStream:
				// see ChatStore.VerifyStreamAction
				break
			case .saveAPIKey:
				// see ChatStore.SaveAPIKeyAction
				break
			}
			return newState
		} middleware: {
			StreamResponseAction()
			GetAPIKeyAction()
			GetAPIKeyAction()
			CheckAPIKeyAction()
			VerifyStreamAction()
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
	
	private class GetAPIKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .getAPIKey(router) = action else {
				return action
			}
			var apiKey: String?
			apiKey = UserDefaults.standard.object(forKey: apiKeyDefaultsName) as? String
			guard let _ = apiKey, await router.state.message == nil else {
				await router.dispatch(action: .signal("getAPIKey"))
				return action
			}
			return action
		}
	}
	
	//  MARK: ChatStore.CheckAPIKeyAction

	private class CheckAPIKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .checkAPIKey(maybeKey, store) = action else {
				return action
			}
			await store.dispatch(action: .setTestAPIKey(maybeKey))
			var stream: AsyncStream<String>?
			do {
				let api = ChatGPTAPI(key: maybeKey)
				stream = try await api.fetchResponseStream(prompt: "?", store: store)
			} catch {
				return action
			}
			guard let stream = stream else {
				return action
			}
			return .setStream(stream)
		}
	}
	
	//  MARK: ChatStore.VerifyStreamAction

	private class VerifyStreamAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .verifyStream(stream, testKey) = action else {
				return action
			}
			for try await _ in stream {
				return .setAPIKey(testKey)
			}
			return .setTestAPIKey("")
		}
	}
	
	//  MARK: ChatStore.SaveAPIKeyAction

	private class SaveAPIKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case let .saveAPIKey(key) = action else {
				return action
			}
			UserDefaults.standard.set(key, forKey: "GPT3_API_KEY")
			return action
		}
	}
	
	//  MARK: ChatStore.PromptAPIKeyAction

	private class PromptAPIKeyAction: Middleware {
		func callAsFunction(action: ChatAction) async -> ChatAction? {
			guard case .promptAPIKey = action else {
				return action
			}
			guard let _ = await store.state.apiKey else {
				return action
			}
			return .clearAPIKey
		}
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
}
