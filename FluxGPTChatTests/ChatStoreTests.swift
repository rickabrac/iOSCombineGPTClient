//
//  ChatStoreTests.swift
//  FluxGPTChatTests
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import XCTest
import Combine
@testable import FluxGPTChat

class ChatStoreTests: XCTestCase {
	
	let chat = ChatStore()
	let api = MockChatAPI("TestResponse.json")
	let responseStreamed = XCTestExpectation()
	let input = "test"
	let output = "There once was a man from Peru\nWho dreamed of eating a big kangaroo\nHe hopped and he skipped\nBut the kangaroo flipped\nAnd said, \"I\'m not your average stew!\""
	
	func testChatStoreSetPrompt() async throws {
		await chat.store.dispatch(action: .setPrompt(input))
		await chat.store.dispatch(action: .updateResponse(input))
		await chat.store.dispatch(action: .setPrompt(input))
		let prompt = await chat.store.state.prompt
		XCTAssertEqual(prompt, input)
		let response = await chat.store.state.response
		XCTAssertEqual(response, "")
	}

	func testChatStoreSetStream() async throws {
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

	func testChatStoreStreamResponse() async throws {
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
	
	func testChatStoreUpdateResponse() async throws {
		await chat.store.dispatch(action: .updateResponse(input))
		let response = await chat.store.state.response
		XCTAssertEqual(response, input)
	}
	
	func testChatStoreEndResponse() async throws {
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
	
	func testChatStoreSetSharing() async throws {
		await chat.store.dispatch(action: .setSharing(true))
		let sharingTrue = await chat.store.state.sharing
		XCTAssertEqual(sharingTrue, true)
		await chat.store.dispatch(action: .setSharing(false))
		let sharingFalse = await chat.store.state.sharing
		XCTAssertEqual(sharingFalse, false)
	}
	
	func testChatStoreThrowError() async throws {
		await chat.store.dispatch(action: .throwError(input))
		let error = await chat.store.state.error
		XCTAssertEqual(error, input)
	}
	
	func testChatStorePresentError() async throws {
		await chat.store.dispatch(action: .presentError)
		let showingError = await chat.store.state.showingError
		XCTAssertEqual(showingError, true)
	}
	
	func testChatStoreClearError() async throws {
		await chat.store.dispatch(action: .presentError)
		let threwShowingError = await chat.store.state.showingError
		XCTAssertEqual(threwShowingError, true)
		await chat.store.dispatch(action: .clearError)
		let clearedShowingError = await chat.store.state.showingError
		XCTAssertEqual(clearedShowingError, false)
	}
	
	func testChatStoreSetAPI() async throws {
		let input = ChatGPTAPI(key: "?")
		await chat.store.dispatch(action: .setAPI(input))
		guard let _ = await chat.store.state.api else {
			XCTFail()
			return
		}
//		XCTAssertEqual(input, output)
	}
	
	func testChatClearAPIKey() async throws {
		await chat.store.dispatch(action: .setAPIKey(input))
		guard let _ = await chat.store.state.apiKey else {
			XCTFail()
			return
		}
		await chat.store.dispatch(action: .clearAPIKey)
		guard let _ = await chat.store.state.apiKey else {
			return
		}
		XCTFail()
	}
	
	func testChatSetTestAPIKey() async throws {
		await chat.store.dispatch(action: .setTestAPIKey(input))
		if await chat.store.state.testAPIKey.count == 0 {
			XCTFail()
			return
		}
		let output = await chat.store.state.testAPIKey
		XCTAssertEqual(input, output)
	}
	
	func testChatSetAPIKey() async throws {
		await chat.store.dispatch(action: .setAPIKey(input))
		guard let output = await chat.store.state.apiKey else {
			XCTFail()
			return
		}
		XCTAssertEqual(input, output)
	}
}
