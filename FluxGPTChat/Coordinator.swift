//
//  Coordinator.swift
//  FluxGPTChat
//  Created by Rick Tyler
//
//  SPDX-License-Identifier: MIT

protocol Coordinator {
	func start()
	func coordinate(to coordinator: Coordinator)
}

extension Coordinator {
	func coordinate(to coordinator: Coordinator) {
		coordinator.start()
	}
}
