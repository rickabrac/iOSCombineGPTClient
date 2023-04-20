//
//  ChatTabUIView.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  SwiftUI tab view allows the user to switch between ChatUIView and ChatViewController,
//  coodidnated by ChatRouter.

import SwiftUI

struct ChatTabUIView: View {
	@StateObject var router: Router
	@SwiftUI.State private var selectedTab = "SwiftUI"

	init(router: Router) {
		self._router = StateObject(wrappedValue: router)
		let tabBarAppearance = UITabBar.appearance()
		tabBarAppearance.unselectedItemTintColor = .gray
	}
	
    var body: some View {
		TabView {
			ChatUIView(router: router)
				.onTapGesture {
					selectedTab = "SwiftUI"
				}
				.tabItem {
					Label("SwiftUI", image: "swiftui")
				}
				.tag("SwiftUI")

			ChatViewControllerUIView(router: router as! ChatRouter, chat: ChatStore.store)
				.onTapGesture {
					selectedTab = "UIKit"
				}
				.tabItem {
					Label("UIKit", image: "uikit")
				}
				.tag("UIKit")
		}
		.background(Image("brain"))
    }
}

//struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatTabUIView()
//    }
//}
