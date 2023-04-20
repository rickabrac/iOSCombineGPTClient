//
//  RouterStoreTests.swift
//  FluxGPTChatTests
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import XCTest
@testable import FluxGPTChat

class RouterStoreTests: XCTestCase {
	let input = "test"
	
	func testChatStoreSetName() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .setName(input))
		let name = await store.state.name
		XCTAssertEqual(name, input)
	}
	
	func testChatStoreSetPath() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .setNext(input))
		await store.dispatch(action: .signal(input))
		await store.dispatch(action: .setPath(input))
		let path = await store.state.path
		XCTAssertEqual(path, input)
		let next = await store.state.next
		XCTAssertEqual(next, "")
		let signal = await store.state.signal
		XCTAssertEqual(signal, nil)
	}
	
	func testChatStoreSetNext() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		await store.dispatch(action: .setNext(input))
		let next = await store.state.next
		XCTAssertEqual(next, input)
		let signal = await store.state.signal
		XCTAssertEqual(signal, nil)
	}
	
	func testChatStoreSignal() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		let signal = await store.state.signal
		XCTAssertEqual(signal, input)
	}
	
	func testChatStoreClearSignal() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		await store.dispatch(action: .respond(input))
		await store.dispatch(action: .clearSignal)
		let signal = await store.state.signal
		XCTAssertEqual(signal, nil)
		let response = await store.state.response
		XCTAssertEqual(response, nil)
	}
	
	func testChatStoreRespond() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .respond(input))
		let response = await store.state.response
		XCTAssertEqual(response, input)
	}
}
