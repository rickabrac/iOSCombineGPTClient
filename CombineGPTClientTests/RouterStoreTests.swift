//
//  RouterStoreTests.swift
//  CombineGPTClientTests
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import XCTest
@testable import CombineGPTClient

class RouterStoreTests: XCTestCase {
	let input = "test"
	
	func test_RouterAction_setName() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .setName(input))
		let name = await store.state.name
		XCTAssertEqual(name, input)
	}
	
	func test_RouterAction_setPath() async throws {
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
	
	func test_RouterAction_setNext() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		await store.dispatch(action: .setNext(input))
		let next = await store.state.next
		XCTAssertEqual(next, input)
		let signal = await store.state.signal
		XCTAssertEqual(signal, nil)
	}
	
	func test_RouterAction_signal() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		let signal = await store.state.signal
		XCTAssertEqual(signal, input)
	}
	
	func test_RouterAction_clearSignal() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .signal(input))
		await store.dispatch(action: .respond(input))
		await store.dispatch(action: .clearSignal)
		let signal = await store.state.signal
		XCTAssertEqual(signal, nil)
		let response = await store.state.response
		XCTAssertEqual(response, nil)
	}
	
	func test_RouterAction_respond() async throws {
		let store = newRouterStore()
		await store.dispatch(action: .respond(input))
		let response = await store.state.response
		XCTAssertEqual(response, input)
	}
}
