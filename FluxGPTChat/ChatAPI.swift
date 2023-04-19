//
//  GPTChatAPI.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  GPT-3 API that returns results using ChatStore and AsyncStream

import Foundation
import Combine

protocol ChatAPIProtocol {
	func fetchResponseStream(prompt: String, store: ChatStoreType) async throws -> AsyncStream<String>
}

class ChatAPI: ChatAPIProtocol {
	private let model = "gpt-3.5-turbo"
	private let systemMessage = Message(role: "system", content: "You are my helpful AI assistant.")
	private let temperature = 0.5
	private var historyList = [Message]()
	private let urlSession = URLSession.shared
	private var cancellables = Set<AnyCancellable>()
	static let apiKeyDefaultsName = "GPT3_API_KEY"
	private var key = ""
	
	init(key: String) {
		self.key = key
	}
	
	private var urlRequest: URLRequest {
		var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
		urlRequest.httpMethod = "POST"
		headers.forEach { urlRequest.setValue($1, forHTTPHeaderField:$0) }
		return urlRequest
	}
	
	private var headers: [String:String] {
		[
			"Content-type" : "application/json",
			"Authorization" : "Bearer \(self.key)",
		]
	}
	
	private let jsonDecoder: JSONDecoder = {
		let jsonDecoder = JSONDecoder()
		jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
		return jsonDecoder
	}()
	
	private func generateMessages(from text: String) -> [Message] {
		return [systemMessage] + [Message(role: "user", content: text)]
	}
	
	private func jsonBody(prompt: String, stream: Bool = true) throws -> Data {
		let request = Request(model: model, temperature: temperature, messages: generateMessages(from: prompt), stream: stream)
		return try! JSONEncoder().encode(request)
	}

	func fetchResponseStream(prompt: String, store: ChatStoreType) async throws -> AsyncStream<String> {
		var urlRequest = self.urlRequest
		do {
			urlRequest.httpBody = try jsonBody(prompt: prompt)
		} catch {
			fatalError("jsonBody() exception: \(error)")
		}
		let (data, response) = try await urlSession.bytes(for: urlRequest)
		if let httpResponse = response as? HTTPURLResponse, (201...299).contains(httpResponse.statusCode) {
			var errorText = ""
			for try await line in data.lines {
				errorText += line
			}
			if let data = errorText.data(using: .utf8), let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
				errorText  = "\n\(errorResponse.message)"
			}
			await store.dispatch(action: .throwError(errorText.localizedDescription))
			throw "Request failed: \(httpResponse.statusCode), \(errorText) "
		}
		let lines = data.lines
		return AsyncStream<String> { continuation in
			Task(priority: .userInitiated) {
				do {
					var jsonError = ""
					for try await line in lines {
						if jsonError.count == 0,
						   line.hasPrefix("data: "),
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
				} catch {
					print(error.localizedDescription)
					await store.dispatch(action: .throwError(error.localizedDescription))
				}
			}
		}
	}
}

// MARK: ChatAPI Equatable conformance

extension ChatAPI: Equatable {
	static func == (lhs: ChatAPI, rhs: ChatAPI) -> Bool {
		lhs.key == rhs.key
	}
}

// MARK: GPTAPI Models

enum HTTPError: LocalizedError {
	case statusCode
}

struct Message: Codable {
	let role: String
	let content: String?
}

struct Request: Codable {
	let model: String
	let temperature: Double
	let messages: [Message]
	let stream: Bool
}

struct ErrorRootResponse: Decodable {
	let error: ErrorResponse
}

struct ErrorResponse: Decodable {
	let message: String
	let type: String?
}
			  
struct StreamCompletionResponse: Decodable {
	let choices: [StreamChoice]
}

struct CompletionResponse: Decodable {
	let choices: [Choice]
	let usage: Usage?
}

struct Usage: Decodable {
	let promptTokens: Int?
	let completionTokens: Int?
	let totalTokesn: Int?
}

struct Choice: Decodable {
	let message: Message
	let finishReason: String?
}

struct StreamChoice: Decodable {
	let finishReason: String?
	let delta: StreamMessage
}

struct StreamMessage: Decodable {
	let content: String?
	let role: String?
}

