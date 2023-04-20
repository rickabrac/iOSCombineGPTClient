//
//  ChatViewControllerTests.swift
//  FluxGPTChatTests
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import XCTest
import SnapshotTesting
@testable import CombineGPTChat

class ChatViewControllerTests: XCTestCase {
	
	var chat: ChatStore? = nil
	let main = MainRouter(UIWindow(), path: "/")
	var router: ChatRouter? = nil
	var vc: ChatViewController? = nil
	let input = "This is a test"
	
	let light = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.light)
	let dark = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.dark)
	
	override func setUpWithError() throws {
//		isRecording = true
		router = ChatRouter(UIWindow(), path: "/chat", parent: main)
		vc = ChatViewController(router: router!)
		if UIScreen.main.bounds != CGRect(x: 0.0, y: 0.0, width: 390.0, height: 844.0) {
			fatalError("Please use the iPhone 13 simulator in portrait mode for snapshot tests")
		}
	}
	
	func asyncSetUpWithError(_ cannedResponseFileName: String) async throws {
		chat = ChatStore()
		let api = MockChatAPI(cannedResponseFileName)
		guard let chat = chat else {
			XCTFail()
			return
		}
		guard let vc = vc else {
			XCTFail()
			return
		}
		await vc.setChatStore(chat)
		await vc.loadView()
		await vc.configure()
		await  chat.store.dispatch(action: .setPrompt(input))
		let stream = try await api.fetchResponseStream(prompt: input, store: chat.store)
		await  chat.store.dispatch(action: .setStream(stream))
		await  chat.store.dispatch(action: .streamResponse(stream, ""))
		while await chat.store.state.stream != nil { }
	}
	
	func test_ChatViewController_NormalResponse_Snapshot_Light() async throws {
		try await asyncSetUpWithError("TestResponse.json")
		guard let vc = vc else {
			XCTFail()
			return
		}
		await vc.overrideUserInterfaceStyle(.light)
		let snapshotTaken = XCTestExpectation()
		DispatchQueue.main.async {
			assertSnapshot(matching: vc, as: .image(on: .iPhoneX, traits: self.light))
			snapshotTaken.fulfill()
		}
		wait(for: [snapshotTaken], timeout: 10)
	}

	func test_ChatViewController_NormalResponse_Snapshot_Dark() async throws {
		try await asyncSetUpWithError("TestResponse.json")
		guard let vc = vc else {
			XCTFail()
			return
		}
		await vc.overrideUserInterfaceStyle(.dark)
		let snapshotTaken = XCTestExpectation()
		DispatchQueue.main.async {
			assertSnapshot(matching: vc, as: .image(on: .iPhoneX, traits: self.dark))
			snapshotTaken.fulfill()
		}
		wait(for: [snapshotTaken], timeout: 10)
	}
}
