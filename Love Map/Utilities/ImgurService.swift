//
//  ImgurService.swift
//  Love Map
//
//  Created by Emma Lu on 3/11/2024.
//

import Foundation
import UIKit

class ImgurService {
    private let clientID = "a6883958f9a2da0" // 替换为您的 Imgur 客户端 ID
    
    func uploadImageToImgur(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // 将图片编码为 Base64
        guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            completion(.failure(NSError(domain: "InvalidImage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
            return
        }
        
        let url = URL(string: "https://api.imgur.com/3/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 创建请求体，指定 type 为 base64
        let body: [String: Any] = [
            "image": imageData,
            "type": "base64"
        ]
        
        // 序列化为 JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(NSError(domain: "JSONSerializationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"])))
            return
        }
        
        // 执行请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            // 打印响应 JSON 以便调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            // 解析 JSON 响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let jsonData = json["data"] as? [String: Any],
                   let link = jsonData["link"] as? String {
                    completion(.success(link))
                } else {
                    print("JSON parsing error: Expected 'data' and 'link' fields.")
                    completion(.failure(NSError(domain: "InvalidJSON", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing 'data' or 'link' fields in response JSON"])))
                }
            } catch {
                print("JSON deserialization error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
