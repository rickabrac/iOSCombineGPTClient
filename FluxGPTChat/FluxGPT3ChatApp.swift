//
//  FluxGPT3ChatApp.swift
//  FluxGPT3Chat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI

@main
struct FluxGPT3ChatApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
    var body: some Scene {
        WindowGroup {
			RootUIView()
        }
    }
}
