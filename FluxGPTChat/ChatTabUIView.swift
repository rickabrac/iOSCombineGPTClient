//
//  MainUIView.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT
//
//  SwiftUI root view tab controller 

import SwiftUI

struct ChatTabUIView: View {
	var router: RouterStoreType
	@SwiftUI.State private var selectedTab = "SwiftUI"

	init(router: RouterStoreType) {
		self.router = router
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
