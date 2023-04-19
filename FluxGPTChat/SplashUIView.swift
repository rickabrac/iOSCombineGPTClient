//
//  SplashUIView.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import SwiftUI

struct SplashUIView: View {
	@StateObject var router: Router
	@SwiftUI.State private var promptingForAPIKey = false
	@SwiftUI.State private var showingAPIKeyError = false
	@SwiftUI.State private var apiKeyDefined = false
	@SwiftUI.State private var apiKey = ""
	@SwiftUI.State private var okDisabled = false
	
	init(router: Router) {
		self._router = StateObject(wrappedValue: router)
	}
	
	private func refreshView() -> some View {
		print("SplashUIView.refreshView()")
		return AnyView(EmptyView())
	}
	
    var body: some View {
		ZStack(alignment: .top) {
			ZStack(alignment: .center) {
				Image("brain")
					.edgesIgnoringSafeArea(.all)
				Text("GPT Chat Client\nby\nRick Tyler")
					.multilineTextAlignment(.center)
			}
		}
    }
}

//struct SplashUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SplashUIView()
//    }
//}
