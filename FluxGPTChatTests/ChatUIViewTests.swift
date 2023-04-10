//
//  ChatUIViewTests.swift
//  FluxGPTChatTests
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import XCTest
import SnapshotTesting
import SwiftUI
import UIKit
@testable import FluxGPTChat

class ChatUIViewTests: XCTestCase {
	
	var vc: UIViewController!
	var chat: ChatStore? = nil
	let input = "This is a test"
	
	let light = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.light)
	let dark = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.dark)

	override func setUpWithError() throws {
//		isRecording = true
		if UIScreen.main.bounds != CGRect(x: 0.0, y: 0.0, width: 390.0, height: 844.0) {
			fatalError("Please use the iPhone 13 simulator in portrait mode for snapshot tests")
		}
	}
	
	func asyncSetUpWithError(_ cannedResponseFileName: String) async throws {
		let store = ChatStore().store
		let api = MockGPT3API("TestResponse.json")
		let stream = try await api.fetchResponseStream(prompt: input, store: store)
		await  store.dispatch(action: .setPrompt(input))
		await  store.dispatch(action: .setStream(stream))
		while await store.state.stream != nil {
			await  store.dispatch(action: .streamResponse(stream, store.state.response))
		}
		let chatView = await ChatUIView(store: store, prompt: input)
		vc = await UIHostingController(rootView: chatView)
		await vc.loadView()
	}

    func test_ChatUIView_NormalResponse_Snapshot_Light() async throws {
		try await asyncSetUpWithError("TestResponse.json")
		let snapshotTaken = XCTestExpectation()
		DispatchQueue.main.async {
			self.vc.overrideUserInterfaceStyle = .light
			assertSnapshot(matching: self.vc, as: .image(on: .iPhoneX, traits: self.light))
			snapshotTaken.fulfill()
		}
		wait(for: [snapshotTaken], timeout: 10)
    }
	
	func test_ChatUIView_NormalResponse_Snapshot_Dark() async throws {
		try await asyncSetUpWithError("TestResponse.json")
		let snapshotTaken = XCTestExpectation()
		DispatchQueue.main.async {
			self.vc.overrideUserInterfaceStyle = .dark
			assertSnapshot(matching: self.vc, as: .image(on: .iPhoneX, traits: self.dark))
			snapshotTaken.fulfill()
		}
		wait(for: [snapshotTaken], timeout: 10)
	}
}
