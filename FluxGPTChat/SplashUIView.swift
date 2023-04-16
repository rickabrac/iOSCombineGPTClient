//
//  SplashUIView.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI

struct SplashUIView: View {
	@StateObject var router: Router
	@SwiftUI.State private var promptingForAPIKey = false
	@SwiftUI.State private var showingAPIKeyError = false
	@SwiftUI.State private var apiKeyDefined = false
	@SwiftUI.State private var apiKey = ""
	@SwiftUI.State var okDisabled = false // true
	
	init(router: Router) {
		self._router = StateObject(wrappedValue: router)
//DispatchQueue.main.async {
//print("SplashUIView: router=\(router)")
//}
//		Task {
//			sleep(1)
//			await router.parent?.store.dispatch(action: .signal("startChat"))
//		}
	}
	
//	func apiKeyErrorView() -> some View {
//		Task {
//			print("******************")
//			print("apiKey=\(store.state.apiKey)")
//			print("testAPIKey=\(store.state.testAPIKey)")
//			print("error=\(store.state.error)")
//			print("stream=\(store.state.stream)")
//			print("promptingForAPIKey=\(promptingForAPIKey)")
//			print("showingAPIKeyError=\(showingAPIKeyError)")
//			print("apiKeyDefined=\(apiKeyDefined)")
//			if store.state.apiKey != nil {
//			// ### USE TIME INTERVAL SINCE LOAD TO DELAY INITIAL PROMPT ###
//				return
//			}
//			await store.dispatch(action: .getAPIKey)
//			if store.state.error.count > 0 {
//				if showingAPIKeyError == false {
//					showingAPIKeyError = true
//				}
//				await store.dispatch(action: .setTestAPIKey(""))
//			} else if let stream = store.state.stream, store.state.testAPIKey.count > 0, promptingForAPIKey {
//				showingAPIKeyError = false
//				await store.dispatch(action: .verifyStream(stream, store.state.testAPIKey))
//			} else if let apiKey = store.state.apiKey {
//				promptingForAPIKey = false
//				showingAPIKeyError = false
//				apiKeyDefined = true
//				await store.dispatch(action: .saveAPIKey(apiKey))
//			} else if store.state.testAPIKey.count == 0 {
//				if promptingForAPIKey == false {
//					Task {
//						promptingForAPIKey = true
//					}
//				}
//			}
//		}
//		if showingAPIKeyError {
//			return AnyView(
//				Text("The key you entered is not valid.")
//					.fontWeight(.semibold)
//			)
//		} else if let _ = store.state.apiKey {
//			return AnyView(EmptyView())
//		}
//		return AnyView(EmptyView())
//	}
	
    var body: some View {
		ZStack(alignment: .top) {
//			apiKeyErrorView()
			ZStack(alignment: .center) {
				Image("brain")
					.edgesIgnoringSafeArea(.all)
				Text("GPT Chat Client\nby\nRick Tyler")
					.multilineTextAlignment(.center)
			}
		}
		.navigate(to: ChatTabUIView(router: router), when: $apiKeyDefined)
//		.textFieldAlert(
//			isShowing: $promptingForAPIKey,
//			text: $apiKey,
//			okDisabled: $okDisabled,
//			title: "Enter a GPT-3 API Key:",
//			store: store
//		)
    }
}

//struct SplashUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SplashUIView()
//    }
//}

extension View {
	func navigate<NewView: View>(to view: NewView, when binding: Binding<Bool>) -> some View {
		NavigationView {
			ZStack {
				self
					.navigationBarTitle("")
					.navigationBarHidden(true)

				NavigationLink(
					destination: view
						.navigationBarTitle("")
						.navigationBarHidden(true),
					isActive: binding
				) {
					EmptyView()
				}
			}
		}
		.navigationViewStyle(.stack)
	}
}

struct TextFieldAlert<Presenting>: View where Presenting: View {
	@Binding var isShowing: Bool
	@Binding var text: String
	@Binding var okDisabled: Bool
	@FocusState private var isFocused: Bool
	let presenting: Presenting
	let title: String
	var store: ChatStoreType

	var body: some View {
		GeometryReader { (deviceSize: GeometryProxy) in
			ZStack {
				self.presenting
					.disabled(isShowing)
				VStack {
					Text(self.title)
					TextField("", text: self.$text)
						.onAppear {
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
								// won't work if delay is too short
								self.isFocused = true
							}
						}
					Divider()
					HStack {
						Button(action: {
							withAnimation {
								Task {
//									await store.dispatch(action: .checkAPIKey(text, store))
								}
								self.isShowing.toggle()
							}
						}) {
							Text("Enter")
						}
					}
				}
				.padding()
				.background(Color.white)
				.autocapitalization(.none)
				.frame(
					width: deviceSize.size.width * 0.7,
					height: deviceSize.size.height * 0.7
				)
				.shadow(radius: 1)
				.opacity(self.isShowing ? 1 : 0)
			}
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					// won't work if delay is too short
					self.isFocused = true
				}
			}
		}
	}
}

fileprivate extension View {
	func textFieldAlert(isShowing: Binding<Bool>, text: Binding<String>, okDisabled: Binding<Bool>, title: String, store: ChatStoreType) -> some View {
		TextFieldAlert(isShowing: isShowing, text: text, okDisabled: okDisabled, presenting: self, title: title, store: store)
	}
}
