//
//  ImageGenAPI.swift
//  CombineGPTClient
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT

import Foundation
import Combine

class ImageGenAPI {
	private let model = "gpt-3.5-turbo"
	private let systemMessage = Message(role: "system", content: "You are my helpful AI assistant.")
	private let temperature = 0.5
	private var historyList = [Message]()
	private let urlSession = URLSession.shared
	private var cancellables = Set<AnyCancellable>()
	private var key = ""
	
	static let apiKeyDefaultsName = "GPT3_API_KEY"
	static var ignoreSavedAPIKey = false
	static var apiKey: String? {
		if ignoreSavedAPIKey {
			return nil
		}
		guard let apiKey = UserDefaults.standard.object(forKey: apiKeyDefaultsName) as? String else {
			return nil
		}
		return apiKey
	}
	
	init(key: String) {
		self.key = key
	}
	
	private var urlRequest: URLRequest {
		var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
		urlRequest.httpMethod = "POST"
		headers.forEach { urlRequest.setValue($1, forHTTPHeaderField:$0) }
		return urlRequest
	}
	
	private var headers: [String:String] { [
			"Content-type" : "application/json",
			"Authorization" : "Bearer \(self.key)",
	] }
	
	private let jsonDecoder: JSONDecoder = {
		let jsonDecoder = JSONDecoder()
		jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
		return jsonDecoder
	}()
	
	private func generateMessages(from text: String) -> [Message] {
		return [systemMessage] + [Message(role: "user", content: text)]
	}
	
	private func jsonBody(prompt: String, size: String, n: Int = 1) throws -> Data {
		let request = Request(prompt: prompt, n: n, size: size)
		return try! JSONEncoder().encode(request)
	}

	func fetchImage(prompt: String, size: String = "1024x1024", store: ChatStoreType, completionHandler: @escaping (String, String) -> Void) {
		var urlRequest = self.urlRequest
		do {
			urlRequest.httpBody = try jsonBody(prompt: prompt, size: size)
		} catch {
			fatalError("jsonBody() exception: \(error)")
		}
		let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
			var imageURL: String = ""
			var errorString: String = ""
			defer {
				completionHandler(imageURL, errorString)
			}
			if let error = error {
				errorString = "\(Response.self).fetch(): generic error (\(error))"
				return
			}
			if let response = response as? HTTPURLResponse, (201...299).contains(response.statusCode) {
				errorString = "ImageAPI.fetchImage: HTTP error (\(response.statusCode))"
				return
			}
			if let data = data, let apiResponse = try? JSONDecoder().decode(Response.self, from: data) {
				imageURL = apiResponse.data[0].url
			}
		})
		task.resume()
	}
	
	// MARK: API Models

	enum HTTPError: LocalizedError {
		case statusCode
	}

	struct Message: Codable {
		let role: String
		let content: String?
	}

	struct Request: Codable {
		let prompt: String
		let n: Int
		let size: String
	}

	struct ErrorRootResponse: Decodable {
		let error: ErrorResponse
	}

	struct ErrorResponse: Decodable {
		let message: String
		let type: String?
	}
		   
	struct Response: Decodable {
		let created: TimeInterval
		let data: [ResponseData]
	}
	
	struct ResponseData: Decodable {
		let url: String
	}
}

// MARK: ImageAPI Equatable conformance

extension ImageGenAPI: Equatable {
	static func == (lhs: ImageGenAPI, rhs: ImageGenAPI) -> Bool {
		lhs.key == rhs.key
	}
}
