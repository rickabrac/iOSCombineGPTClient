//
//  Extensions.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

import Foundation
import SwiftUI
import Combine

//  MARK: Store extension

extension Store {
	func bindStateObserver(_ stateChangeHandler: @escaping () -> Void, cancellables: inout Set<AnyCancellable>) async {
		self.objectWillChange.sink { _ in
			stateChangeHandler()
		}
		.store(in: &cancellables)
	}
}

//  MARK: UIViewController extension

extension UIViewController {
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

//  MARK: Array extension

extension Array where Element == Message {
	var contentCount: Int { reduce(0, { $0 + $1.content!.count }) }
}

//  MARK: String CustomNSError conformance
	
extension String: CustomNSError {
	public var errorUserInfo: [String : Any] { [ NSLocalizedDescriptionKey: self ] }
}

