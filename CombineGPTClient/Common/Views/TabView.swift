//
//  TabView.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Reusable TabView configurable by passing TabView.Item array to initializer.

import SwiftUI

struct TabView: View {
	
	struct Item {
		let text: String
		let image: String
		let view: AnyView
	}

	@StateObject var router: Router
	@SwiftUI.State private var selectedTab = "SwiftUI"
	var tabItems: [Item]
	
	init(router: Router, tabItems: [Item] ) {
		self._router = StateObject(wrappedValue: router)
		self.tabItems = tabItems
		let tabBarAppearance = UITabBar.appearance()
		tabBarAppearance.unselectedItemTintColor = .gray
	}
	
	var body: some View {
		SwiftUI.TabView {
			ForEach(0..<tabItems.count) { index in
				let tabItem = tabItems[index]
				tabItem.view
					.onTapGesture {
						selectedTab = tabItem.text
					}
					.tabItem {
						Label(tabItem.text, image: tabItem.image)
					}
					.tag(tabItem.text)
			}
		}
		.background(Image("brain"))
	}
}

//struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatTabView()
//    }
//}
