//
//  ChatViewControllerUIView.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import SwiftUI

struct ChatViewControllerUIView: UIViewControllerRepresentable {
	func makeUIViewController(context: Context) -> ChatViewController {
		return ChatViewController()
	}
	
	func updateUIViewController(_ uiViewController: ChatViewController, context: Context) { }
}
