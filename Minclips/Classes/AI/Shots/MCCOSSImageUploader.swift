import UIKit
import Combine
import Data
import AliyunOSSiOS

public enum MCCOSSImageUploadError: Error {

    case missingImageData
    case missingObjectKey
    case ossPutFailed(NSError)
    case backend(MCENetworkError)
}

/// `composeSeed` 上传链路：每张图先调 `ossToken` 拿 STS（包含 `objectPath`），再用 AliyunOSS PUT 同一个 key；最终 `objectPath` 列表给 `composeSeed.imageList`。
public final class MCCOSSImageUploader {

    public static let shared = MCCOSSImageUploader()

    private init() {}

    /// 顺序上传，输出顺序与输入顺序对应（保留 character slot 顺序）。失败立刻终止。
    public func mcvc_uploadCharacterImages(_ images: [UIImage]) -> AnyPublisher<[String], MCCOSSImageUploadError> {
        guard !images.isEmpty else {
            return Just([]).setFailureType(to: MCCOSSImageUploadError.self).eraseToAnyPublisher()
        }
        return images.publisher
            .setFailureType(to: MCCOSSImageUploadError.self)
            .flatMap(maxPublishers: .max(1)) { [weak self] image -> AnyPublisher<String, MCCOSSImageUploadError> in
                guard let self else {
                    return Fail(error: .missingObjectKey).eraseToAnyPublisher()
                }
                return self.mcvc_uploadOneImage(image)
            }
            .collect()
            .eraseToAnyPublisher()
    }

    private func mcvc_uploadOneImage(_ image: UIImage) -> AnyPublisher<String, MCCOSSImageUploadError> {
        guard let data = image.jpegData(compressionQuality: 0.92) ?? image.pngData() else {
            return Fail(error: .missingImageData).eraseToAnyPublisher()
        }
        var rq = MCSCfOssTokenRequest()
        rq.mimeKind = "image"
        rq.fileSuffix = "png"
        return MCCCfAPIManager.shared.ossToken(with: rq)
            .mapError { MCCOSSImageUploadError.backend($0) }
            .flatMap { [weak self] token -> AnyPublisher<String, MCCOSSImageUploadError> in
                guard let self else {
                    return Fail(error: .missingObjectKey).eraseToAnyPublisher()
                }
                return self.mcvc_putToOSS(data: data, token: token)
            }
            .eraseToAnyPublisher()
    }

    /// AliyunOSS `uploadData:` 旧式 block API，避免直接处理 `OSSTask`。
    private func mcvc_putToOSS(data: Data, token: MCSCfOssTokenResponse) -> AnyPublisher<String, MCCOSSImageUploadError> {
        Future<String, MCCOSSImageUploadError> { promise in
            let key = token.objectPath.trimmingCharacters(in: .whitespacesAndNewlines)
            let bucket = token.bucketName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !bucket.isEmpty else {
                promise(.failure(.missingObjectKey))
                return
            }
            let endpoint = Self.mcvc_normalizedEndpoint(token.endpoint)
            let provider = OSSStsTokenCredentialProvider(
                accessKeyId: token.cloudAccessKeyId,
                secretKeyId: token.cloudSecretKey,
                securityToken: token.sessionToken
            )
            let cfg = OSSClientConfiguration()
            cfg.timeoutIntervalForRequest = 30
            cfg.timeoutIntervalForResource = 60 * 30
            cfg.maxRetryCount = 2
            let client = OSSClient(endpoint: endpoint, credentialProvider: provider, clientConfiguration: cfg)
            client.uploadData(
                data,
                withContentType: "image/jpeg",
                withObjectMeta: [:],
                toBucketName: bucket,
                toObjectKey: key,
                onCompleted: { ok, err in
                    if ok {
                        promise(.success(key))
                    } else {
                        let nsErr = (err as NSError?) ?? NSError(domain: "MCCOSSImageUploader", code: -1, userInfo: nil)
                        promise(.failure(.ossPutFailed(nsErr)))
                    }
                },
                onProgress: { _ in }
            )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private static func mcvc_normalizedEndpoint(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
