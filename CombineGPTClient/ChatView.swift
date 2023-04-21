//
//  ChatView.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  SwiftUI implementation of the chat interface

import SwiftUI

struct ChatView: View {
	@StateObject var router: Router
	@StateObject var store: ChatStoreType
	@SwiftUI.State private var prompt = ""
	@SwiftUI.State private var sharingResponse = false
	@SwiftUI.State private var showingError = false
	@FocusState private var isFocused: Bool
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	init(router: Router, store: ChatStoreType = ChatStore.store, prompt: String = "") {
		self._router = StateObject(wrappedValue: router)
		self._store = StateObject(wrappedValue: store)
		self._prompt = .init(initialValue: prompt)
		Task {
			await store.dispatch(action: .setRouter(router.store))
			await store.dispatch(action: .getGPTKey(router.store))
		}
	}
	
	private func progressView() -> some View {
		if let signal = router.store.state.signal, let message = router.store.state.response {
			if signal == "getGPTKey", message.starts(with: "apiKey:") {
				if let apiKey = message.components(separatedBy: ":").last {
					Task {
						await store.dispatch(action: .setAPIKey(apiKey))
						await router.store.dispatch(action: .clearSignal)
					}
				}
			} else {
				fatalError("ChatView.progressView: unknown router message (\(message))")
			}
		}
		guard let apiKey = store.state.apiKey else {
			guard let _ = router.store.state.signal else {
				Task {
					await store.dispatch(action: .getGPTKey(router.store))
				}
				return AnyView(EmptyView())
			}
			return AnyView(EmptyView())
		}
		guard let api = store.state.api else {
			Task {
				await store.dispatch(action: .setAPI(ChatAPI(key: apiKey)))
			}
			return AnyView(EmptyView())
		}
		if store.state.prompt.count > 0, store.state.stream == nil {
			return AnyView(
				ProgressView()
				.scaleEffect(1.0, anchor: .center)
				.padding(.leading)
				.padding(.trailing)
				.onAppear {
					Task {
						let stream = try await api.fetchResponseStream(prompt: prompt, store: store)
						await store.dispatch(action: .setStream(stream))
					}
				}
			)
		} else if store.state.isSharingResponse {
			return AnyView(
				ProgressView()
				.scaleEffect(1.0, anchor: .center)
				.padding(.leading)
				.padding(.trailing)
				.onDisappear {
					Task {
						await store.dispatch(action: .setSharing(false))
					}
				}
			)
		} else if store.state.stream == nil {
			return AnyView(EmptyView())
		} else {
			Task {
				guard let stream = store.state.stream else {
					return
				}
				await store.dispatch(action: .streamResponse(stream, store.state.response))
			}
		}
		return AnyView(Text(""))
	}
	
	private func alertView() -> some View {
		if store.state.error.count > 0,
		   store.state.isShowingError == false,
		   showingError == false {
			Task {
				await store.dispatch(action: .presentError)
				showingError = true
			}
		}
		return Text("")
	}
	
	private var showResponse: Bool {
		if store.state.response.count == 0 {
			return false
		}
		return true
	}

	private var shareable: Bool {
		guard let _ = store.state.stream else {
			return false
		}
		return true
	}
	
	func getResponses() -> [String] {
		let responses = [
			store.state.response
		]
		return responses
	}
	
	var body: some View {
		NavigationView() {
			ZStack(alignment: .center) {
				VStack(alignment: .leading) {
					MyTextField("Ask me anything", text: $prompt)
						.frame(height: 18)
						.padding(.top, 10)
						.padding(.leading, 20)
						.padding(.trailing, 20)
						.focused($isFocused)
						.onAppear {
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
								// won't work if delay is too short
								self.isFocused = true
							}
						}
						.onSubmit {
							Task {
								if store.state.stream != nil { return }
									await store.dispatch(action: .setPrompt(prompt))
							}
						}
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.accentColor(colorScheme == .dark ? .white : .black)
						.font(.system(size: 15, weight: .regular, design: .default))
					Spacer().frame(height: 12)
					if showResponse {
						ScrollView(.vertical) {
							ScrollViewReader { scrollView in
								VStack(alignment: .leading, spacing: 0) {
									ForEach(getResponses(), id: \.self) { response in
										Text(store.state.response)
											.font(.system(size: 15, weight: .regular, design: .default))
											.lineSpacing(5)
											.padding(.top, 15)
											.padding(.leading, 25)
											.padding(.trailing, 20)
											.padding(.bottom, 0)
											.frame(maxWidth: .infinity, alignment: .leading)
										Text("")
											.id("bottom")
									}
								}
								.onChange(of: store.state.response) { _ in
									withAnimation {
										scrollView.scrollTo("bottom", anchor: .bottom)	// ### NOT WORKING IN XCODE 13.2.1 ###
									}
								}
							}
						}
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: UIScreen.main.bounds.size.height - 200, alignment: Alignment.top)
						.multilineTextAlignment(.leading)
					}
				}
				.sheet(isPresented: $sharingResponse,
					onDismiss: {
						sharingResponse = false
						Task {
							await store.dispatch(action: .setSharing(false))
						}
					}, content: {
						ShareSheet(activityItems: [store.state.response])
					})
				.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: Alignment.topLeading)
				progressView()
				alertView()
					.alert(isPresented: $showingError, content: {
						Alert(title: Text("Fetch Error"), message: Text("\n\(store.state.error)"),
						  dismissButton: .default(Text("OK"), action: {
							Task {
								await store.dispatch(action: .clearError)
							}
						}))
					})
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text("SwiftUI GPT Chat")
						.font(.system(size: 17, weight: .semibold, design: .default))
						.accessibilityAddTraits(.isHeader)
				}
			}
			.navigationBarItems(trailing:
				Button(action: {
					sharingResponse = true;
					Task {
						await store.dispatch(action: .setSharing(true))
					}
				}) {
					Image(systemName: "square.and.arrow.up")
				}
				.opacity(store.state.stream == nil && store.state.response != "" ? 1.0 : 0.0)
			)
		}
	}
	
	private struct MyTextField: View {
		let title: String
		@Binding var text: String
		@SwiftUI.State private var isEditing: Bool = false
		@FocusState private var isFocused: Bool

		init(_ title: String, text: Binding<String>) {
			self.title = title
			self._text = text
		}

		var body: some View {
			ZStack(alignment: .trailing) {
				TextField(self.title, text: self.$text) { isEditing in
					self.isEditing = isEditing
				} onCommit: {
					self.isEditing = false
				}
				.textFieldStyle(.plain)
				.frame(height: 43)
				.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 25))
				.cornerRadius(8)
				.overlay( RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)).stroke(.primary, lineWidth: 1.0).border(.gray).cornerRadius(8) )
				.font(.system(size: 15, weight: .regular, design: .default))
				.focused($isFocused)
				if self.text.count > 0 {
					Button {
						self.text = ""
						self.isFocused = true
					} label: {
						Image(systemName: "multiply.circle.fill").foregroundColor(.secondary)
					}
					.buttonStyle(PlainButtonStyle())
					.padding(5)
				}
			}
			.frame(alignment: .trailing)
		}
	}
	
	private struct ShareSheet: UIViewControllerRepresentable {
		typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void

		let activityItems: [Any]
		let applicationActivities: [UIActivity]? = nil
		let excludedActivityTypes: [UIActivity.ActivityType]? = nil
		let callback: Callback? = nil
		
		func makeUIViewController(context: Context) -> UIActivityViewController {
			let controller = UIActivityViewController(
				activityItems: activityItems,
				applicationActivities: applicationActivities)
			controller.excludedActivityTypes = excludedActivityTypes
			controller.completionWithItemsHandler = callback
			return controller
		}

		func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
	}
}
