//
//  MainUIView.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI

struct ChatTabUIView: View {
	@StateObject var router: Router
	@SwiftUI.State private var selectedTab = "SwiftUI"

	init(router: Router) {
		self._router = StateObject(wrappedValue: router)
//DispatchQueue.main.async {
//print("ChatTabUIView: router=\(router)")
//}
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

			ChatViewControllerUIView()
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
