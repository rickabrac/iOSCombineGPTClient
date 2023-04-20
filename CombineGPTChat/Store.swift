//
// Store.swift
// Copyright 2022 Neudesic, LLC
// SPDX-License-Identifier: MIT

import Combine
import Foundation

protocol State {
	init()
}

protocol Middleware {
	associatedtype Action

	func callAsFunction(action: Action) async -> Action?
}

struct AnyMiddleware<Action>: Middleware {
	private let wrappedMiddleware: (Action) async -> Action?

	init<M: Middleware>(_ middleware: M) where M.Action == Action {
		self.wrappedMiddleware = middleware.callAsFunction(action:)
	}

	func callAsFunction(action: Action) async -> Action? {
		return await wrappedMiddleware(action)
	}
}

extension Middleware {
	func eraseToAnyMiddleware() -> AnyMiddleware<Action> {
		return self as? AnyMiddleware<Action> ?? AnyMiddleware(self)
	}
}

struct EchoMiddleware<Action>: Middleware {
	func callAsFunction(action: Action) async -> Action? {
		return action
	}
}

struct MiddlewarePipeline<Action>: Middleware {
	private let middleware: [AnyMiddleware<Action>]

	init(_ middleware: AnyMiddleware<Action>...) {
		self.middleware = middleware
	}

	init(_ middleware: [AnyMiddleware<Action>]) {
		self.middleware = middleware
	}

	func callAsFunction(action: Action) async -> Action? {
		var currentAction: Action = action
		for m in middleware {
			guard let newAction = await m(action: currentAction) else {
				return nil
			}

			currentAction = newAction
		}

		return currentAction
	}
}

@resultBuilder
struct MiddlewareBuilder<Action> {
	static func buildArray(
		_ components: [MiddlewarePipeline<Action>]
	) -> AnyMiddleware<Action> {
		MiddlewarePipeline(components.map { $0.eraseToAnyMiddleware() })
			.eraseToAnyMiddleware()
	}

	static func buildBlock(
		_ components: AnyMiddleware<Action>...
	) -> MiddlewarePipeline<Action> {
		.init(components)
	}

	static func buildEither<M: Middleware>(
		first component: M
	) -> AnyMiddleware<Action> where M.Action == Action {
		component.eraseToAnyMiddleware()
	}

	static func buildEither<M: Middleware>(
		second component: M
	) -> AnyMiddleware<Action> where M.Action == Action {
		component.eraseToAnyMiddleware()
	}

	static func buildExpression<M: Middleware>(
		_ expression: M
	) -> AnyMiddleware<Action> where M.Action == Action {
		expression.eraseToAnyMiddleware()
	}

	static func buildFinalResult<M: Middleware>(
		_ component: M
	) -> AnyMiddleware<Action> where M.Action == Action {
		component.eraseToAnyMiddleware()
	}

	static func buildOptional(
		_ component: MiddlewarePipeline<Action>?
	) -> AnyMiddleware<Action> {
		guard let component = component else {
			return EchoMiddleware<Action>().eraseToAnyMiddleware()
		}

		return component.eraseToAnyMiddleware()
	}
}

actor Store<S: State, Action>: ObservableObject {
	typealias Reducer = (S, Action) -> S

	@MainActor @Published private(set) var state: S = .init()

	private let middleware: AnyMiddleware<Action>
	private let reducer: Reducer

	init<M: Middleware>(
		reducer: @escaping Reducer,
		@MiddlewareBuilder<Action> middleware: () -> M
	) where M.Action == Action {
		self.reducer = reducer
		self.middleware = middleware().eraseToAnyMiddleware()
	}

	convenience init(reducer: @escaping Reducer) {
		self.init(
			reducer: reducer,
			middleware: {
				EchoMiddleware<Action>()
			}
		)
	}

	func dispatch(action: Action) async {
		guard let newAction = await middleware(action: action) else {
			return
		}

		await MainActor.run {
			let currentState = state
			let newState = reducer(currentState, newAction)
			state = newState
		}
	}
}

extension Store {
	func dispatch(_ factory: () async -> Action) async {
		await self.dispatch(action: await factory())
	}
}

extension Store {
	func dispatch<Seq: AsyncSequence>(
		sequence: Seq
	) async throws where Seq.Element == Action {
		for try await action in sequence {
			await dispatch(action: action)
		}
	}
}

extension Store {
	func dispatch(future: Future<Action?, Never>) {
		var subscription: AnyCancellable?
		subscription = future.sink { _ in
			if subscription != nil {
				subscription = nil
			}
		} receiveValue: { action in
			guard let action = action else {
				return
			}

			Task {
				await self.dispatch(action: action)
			}
		}
	}
}

extension Store {
	func dispatch<P: Publisher>(publisher: P) where P.Output == Action, P.Failure == Never {
		var subscription: AnyCancellable?
		subscription = publisher.sink { _ in
			if subscription != nil {
				subscription = nil
			}
		} receiveValue: { action in
			Task {
				await self.dispatch(action: action)
			}
		}
	}
}
