import Foundation
import SwiftGodot

struct NetworkManager {
	
	enum NetworkError: Error {
		case requestFailed
		case invalidResponse
		case serverError(code: Int)
		case configurationError(gdError: GodotError)
	}

	private static let host = "http://127.0.0.1:8080"

	static func jsonRequest<T: Decodable>(
			node: Node,
			url: String,
			method: HTTPClient.Method, 
			headers: PackedStringArray = [], 
			body: Data? = nil, 
			completion: @escaping (Result<T, Error>) -> Void
			) {

		let httpRequest = HTTPRequest()
		node.addChild(node: httpRequest)

		headers.append("Content-Type: application/json")
		let bodyString: String
		if let body {
			bodyString = String(data: body, encoding: .utf8) ?? ""
		} else {
			bodyString = ""
		}
						
		httpRequest.requestCompleted.connect { result, responseCode, responseHeaders, responseBody in
			if result == 0 {
				if responseCode == 200 {
					let data = Data(responseBody.asBytes())
					do {
						let reponseObject = try JSONDecoder().decode(T.self, from: data)
						completion(.success(reponseObject))
					} catch {
						completion(.failure(error))
					}
				} else {
					completion(.failure(NetworkError.serverError(code: Int(responseCode))))
				}
			} else {
				completion(.failure(NetworkError.requestFailed))
			}
		}
			
		let error = httpRequest.request(url: host + url, customHeaders: headers, method: method, requestData: bodyString)
		if error != .ok {
			completion(.failure(NetworkError.configurationError(gdError: error)))
		}
	}
}
