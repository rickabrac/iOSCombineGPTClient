//
//  MockChatAPI.swift
//  CombineGPTClientTests
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import Foundation
@testable import CombineGPTClient

class MockChatAPI: ChatAPIProtocol {
	private let cannedResponseFileName: String
	private let cannedResponseFileExtension: String
	
	init(_ cannedResponseFileName: String) {
		let parts = cannedResponseFileName.split(separator: ".")
		self.cannedResponseFileName = String(parts[0])
		self.cannedResponseFileExtension = String(parts[1])
	}
	
	func fetchResponseStream(prompt: String, store: ChatStoreType) async throws -> AsyncStream<String> {
		if let path = Bundle.main.path(forResource: cannedResponseFileName, ofType: cannedResponseFileExtension),
		   let _ = freopen(path, "r", stdin) {
			return AsyncStream<String> { continuation in
				Task(priority: .userInitiated) {
					var jsonError = ""
					while let line = readLine() {
						let jsonDecoder = JSONDecoder()
						jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
						if line.hasPrefix("data: "),
						  let data = line.dropFirst(6).data(using: .utf8),
						  let response = try? jsonDecoder.decode(StreamCompletionResponse.self, from: data) {
							if let text = response.choices.first?.delta.content {
								continuation.yield(text)
							}
						} else if line != "data: [DONE]" {
						   jsonError += line
						}
					}
					if jsonError.count > 0 {
						do {
							if let json = jsonError.data(using: String.Encoding.utf8){
								if let errorDict = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:AnyObject],
								   let error = errorDict["error"] as? [String: String?],
								   let message = error["message"]! {
									await store.dispatch(action: .throwError(message))
								} else {
									await store.dispatch(action: .throwError("Unknown error"))
								}
							}
						} catch {
							await store.dispatch(action: .throwError(error.localizedDescription))
						}
					}
					continuation.finish()
				}
			}
		}
		return AsyncStream<String> { _ in }
	}
}
