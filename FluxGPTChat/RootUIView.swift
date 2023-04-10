//
//  RootView.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI

struct RootUIView: View {
	@SwiftUI.State private var selectedTab = "SwiftUI"

    var body: some View {
		TabView {
			ChatUIView()
				.onTapGesture {
					selectedTab = "SwiftUI"
				}
				.tabItem {
					Label("SwiftUI", systemImage: "star")
				}
				.tag("SwiftUI")

			ChatViewControllerUIView()
				.onTapGesture {
					selectedTab = "UIKit"
				}
				.tabItem {
					Label("UIKit", systemImage: "star")
				}
				.tag("UIKit")
		}
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootUIView()
    }
}
