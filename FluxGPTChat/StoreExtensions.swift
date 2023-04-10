//
//  StoreExtensions.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT


import Foundation
import SwiftUI
import Combine

extension Store {
	func bindStateChangeHandler(_ stateChangeHandler: @escaping () -> Void, cancellables: inout Set<AnyCancellable>) async {
		self.objectWillChange.sink { _ in
			stateChangeHandler()
		}
		.store(in: &cancellables)
	}
}

protocol StoreSubscriber {
	static var cancellables: Set<AnyCancellable> { get }
}

extension UIViewController: StoreSubscriber {
	private static var _cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
	
	static var cancellables: Set<AnyCancellable> {
		get {
			return _cancellables
		}
		set {
			_cancellables = newValue
		}
	}
}

