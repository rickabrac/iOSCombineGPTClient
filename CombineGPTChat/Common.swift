//
//  Common.swift
//  CombineGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Global extensions

import Foundation
import SwiftUI
import Combine

//  MARK: Store extension

extension Store {

	func bindStateObserver(_ stateChangeHandler: @escaping () -> Void, _ pool: inout Set<AnyCancellable>) async {
		self.objectWillChange.sink { _ in
			stateChangeHandler()
		}
		.store(in: &pool)
	}
}

//  MARK: UIViewController extension

extension UIViewController {
	private static var _pool: Set<AnyCancellable> = Set<AnyCancellable>()
	
	static var pool: Set<AnyCancellable> {
		get {
			return _pool
		}
		set {
			_pool = newValue
		}
	}
}

//  MARK: String CustomNSError conformance

extension String: CustomNSError {
	public var errorUserInfo: [String : Any] { [ NSLocalizedDescriptionKey: self ] }
}
