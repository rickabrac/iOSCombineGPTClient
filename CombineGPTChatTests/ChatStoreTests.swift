//
//  ChatStoreTests.swift
//  CombineGPTChatTests
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import XCTest
import Combine
@testable import CombineGPTChat

class ChatStoreTests: XCTestCase {
	
	let chat = ChatStore()
	let api = MockChatAPI("TestResponse.json")
	let responseStreamed = XCTestExpectation()
	let input = "test"
	let output = "There once was a man from Peru\nWho dreamed of eating a big kangaroo\nHe hopped and he skipped\nBut the kangaroo flipped\nAnd said, \"I\'m not your average stew!\""
	
	func test_ChatAction_setPrompt() async throws {
		await chat.store.dispatch(action: .setPrompt(input))
		await chat.store.dispatch(action: .updateResponse(input))
		await chat.store.dispatch(action: .setPrompt(input))
		let prompt = await chat.store.state.prompt
		XCTAssertEqual(prompt, input)
		let response = await chat.store.state.response
		XCTAssertEqual(response, "")
	}

	func test_ChatAction_setStream() async throws {
		let inputStream = try await api.fetchResponseStream(prompt: "", store: chat.store)
		await chat.store.dispatch(action: .setPrompt(input))
		await chat.store.dispatch(action: .throwError(input))
		await chat.store.dispatch(action: .setStream(inputStream))
		let stream = await chat.store.state.stream
		if stream == nil { XCTFail() }
		let response = await chat.store.state.response
		XCTAssertEqual(response, "")
		let error = await chat.store.state.error
		XCTAssertEqual(error, "")
	}
		
	@MainActor func chatStoreStateDidChange(_ state: ChatState) {
		if state.stream == nil {
			// stream ended
			XCTAssertEqual(state.response, output)
			responseStreamed.fulfill()
		}
	}

	func test_ChatAction_streamResponse() async throws {
		var cancellables = Set<AnyCancellable>()
		chat.store.objectWillChange.sink { [weak self] in
			guard let self = self else {
				return
			}
			Task {
				await self.chatStoreStateDidChange(self.chat.store.state)
			}
		}.store(in: &cancellables)
		let stream = try await api.fetchResponseStream(prompt: input, store: chat.store)
		await chat.store.dispatch(action: .setStream(stream))
		await chat.store.dispatch(action: .setPrompt(input))
		while await chat.store.state.stream != nil {
			await chat.store.dispatch(action: .streamResponse(stream, chat.store.state.response))
		}
		wait(for: [responseStreamed], timeout: 5)
	}
	
	func test_ChatAction_updateResponse() async throws {
		await chat.store.dispatch(action: .updateResponse(input))
		let response = await chat.store.state.response
		XCTAssertEqual(response, input)
	}
	
	func test_ChatAction_endResponse() async throws {
		await chat.store.dispatch(action: .setPrompt(input))
		await chat.store.dispatch(action: .updateResponse(output))
		await chat.store.dispatch(action: .endResponse)
		let response = await chat.store.state.response
		XCTAssertEqual(response, output)
		let prompt = await chat.store.state.prompt
		XCTAssertEqual(prompt, "")
		let stream = await chat.store.state.stream
		if stream != nil { XCTFail() }
	}
	
	func test_ChatAction_setSharing() async throws {
		await chat.store.dispatch(action: .setSharing(true))
		let sharingTrue = await chat.store.state.isSharingResponse
		XCTAssertEqual(sharingTrue, true)
		await chat.store.dispatch(action: .setSharing(false))
		let sharingFalse = await chat.store.state.isSharingResponse
		XCTAssertEqual(sharingFalse, false)
	}
	
	func test_ChatAction_throwError() async throws {
		await chat.store.dispatch(action: .throwError(input))
		let error = await chat.store.state.error
		XCTAssertEqual(error, input)
	}
	
	func test_ChatAction_presentError() async throws {
		await chat.store.dispatch(action: .presentError)
		let showingError = await chat.store.state.isShowingError
		XCTAssertEqual(showingError, true)
	}
	
	func test_ChatAction_clearError() async throws {
		await chat.store.dispatch(action: .presentError)
		let threwShowingError = await chat.store.state.isShowingError
		XCTAssertEqual(threwShowingError, true)
		await chat.store.dispatch(action: .clearError)
		let clearedShowingError = await chat.store.state.isShowingError
		XCTAssertEqual(clearedShowingError, false)
	}
	
	func test_ChatAction_getGPTKey() async throws {
		guard let chatRouterStore = ChatRouter.instance?.store else {
			XCTFail()
			return
		}
		ChatGPTAPI.ignoreSavedAPIKey = true
		await chat.store.dispatch(action: .getGPTKey(chatRouterStore))
		guard let chatRouterSignal = await ChatRouter.instance?.store.state.signal else {
			XCTFail()
			return
		}
		XCTAssertEqual(chatRouterSignal, "getGPTKey")
		guard let appRouterSignal = await ChatRouter.instance?.store.state.signal else {
			XCTFail()
			return
		}
		XCTAssertEqual(appRouterSignal, "getGPTKey")
	}
	
	func testChatStoreSetTestAPIKey() async throws {
		await chat.store.dispatch(action: .setTestAPIKey(input))
		let testAPIKey = await chat.store.state.testAPIKey
		XCTAssertEqual(input, testAPIKey)
	}
	
	func test_ChatAction_tryTestAPIKey() async throws {
		let stream = try await api.fetchResponseStream(prompt: "?", store: chat.store)
		await chat.store.dispatch(action: .tryTestAPIKey(stream, input))
		let apiKey = await chat.store.state.apiKey
		XCTAssertEqual(apiKey, input)
	}

	func test_ChatAction_setAPIKey() async throws {
		await chat.store.dispatch(action: .setAPIKey(input))
		guard let output = await chat.store.state.apiKey else {
			XCTFail()
			return
		}
		XCTAssertEqual(input, output)
	}
	
	func test_ChatAction_setAPI() async throws {
		let apiInput = ChatGPTAPI(key: "?")
		await chat.store.dispatch(action: .setAPI(apiInput))
		guard let apiOutput = await chat.store.state.api as? ChatGPTAPI else {
			XCTFail()
			return
		}
		XCTAssertEqual(apiOutput, apiInput)
	}
}
