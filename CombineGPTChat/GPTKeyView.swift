//
//  GPTKeyView.swift
//  CombineGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  SwiftUI view that prompts for and validates a GPT-3 API Key, coordinated by MainRouter.

import SwiftUI

struct GPTKeyView: View {
	
	@StateObject var router: Router
	@StateObject var store: ChatStoreType
	@FocusState var isFocused: Bool
	@SwiftUI.State private var tryKey = ""
	@SwiftUI.State private var error = ""
	@Environment(\.dismiss) var dismiss
	
	init(router: Router, store: ChatStoreType) {
		self._router = StateObject(wrappedValue: router)
		self._store = StateObject(wrappedValue: store)
	}
	
	func apiKeyPromptView() -> some View {
		Task {
			if let key = store.state.apiKey {
				await router.store.dispatch(action: .respond("apiKey:\(key)"))
				return
			} else {
				let error = store.state.error
				if error.count > 0 {
					self.error = error
					if isFocused == false {
						isFocused = true
						tryKey = ""
					}
				}
				let testKey = store.state.testAPIKey
				if testKey.count > 0 {
					if let stream = store.state.stream {
						await store.dispatch(action: .tryTestAPIKey(stream, testKey))
					} else {
						let api = ChatGPTAPI(key: testKey)
						let stream = try await api.fetchResponseStream(prompt: "", store: store)
						await store.dispatch(action: .setStream(stream))
					}
				}
			}
		}
		return AnyView(
			VStack {
				Spacer()
					.frame(height: 20)
				Text("Please enter a GPT-3 API Key:")
					.foregroundColor(.blue)
				Spacer()
					.frame(height: 15)
				TextField("", text: $tryKey)
					.background(.white)
					.foregroundColor(.black)
					.multilineTextAlignment(.center)
					.focused($isFocused)
					.onAppear {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							self.isFocused = true
						}
					}
					.onSubmit {
						Task {
							await store.dispatch(action: .setTestAPIKey(tryKey))
						}
					}
				Spacer()
					.frame(height: 5)
				Divider()
				Spacer()
					.frame(height: 15)
				HStack {
					Button(action: {
						Task {
							await store.dispatch(action: .setTestAPIKey(tryKey))
						}
					}) {
						Text("Enter")
					}
				}
				Spacer()
					.frame(height: 20)
			}
			.cornerRadius(15)
			.background(.white)
			.autocapitalization(.none)
		)
	}
	
	var body: some View {
		ZStack {
			Image("brain")
				.edgesIgnoringSafeArea(.all)
			HStack {
				Spacer().frame(width: 20)
			apiKeyPromptView()
				Spacer().frame(width: 20)
			}
			VStack {
				Spacer()
				Text(error)
					.foregroundColor(.red)
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
		}
	}
}
