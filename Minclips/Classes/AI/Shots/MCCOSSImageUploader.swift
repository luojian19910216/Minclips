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

public final class MCCOSSImageUploader {

    public static let shared = MCCOSSImageUploader()

    private init() {}

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

    public func mcvc_resolveImageListURLs(
        images: [UIImage?],
        existingRemoteURLs: [String?]
    ) -> AnyPublisher<[String], MCCOSSImageUploadError> {
        guard !images.isEmpty, images.count == existingRemoteURLs.count else {
            return Fail(error: .missingImageData).eraseToAnyPublisher()
        }
        let n = images.count
        return Array(0 ..< n).publisher
            .setFailureType(to: MCCOSSImageUploadError.self)
            .flatMap(maxPublishers: .max(1)) { [weak self] idx -> AnyPublisher<String, MCCOSSImageUploadError> in
                let trimmedRemote = existingRemoteURLs[idx]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !trimmedRemote.isEmpty {
                    return Just(trimmedRemote)
                        .setFailureType(to: MCCOSSImageUploadError.self)
                        .eraseToAnyPublisher()
                }
                guard let self, let img = images[idx] else {
                    return Fail(error: .missingImageData).eraseToAnyPublisher()
                }
                return self.mcvc_uploadOneImage(img)
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
                        promise(.success(Self.mcvc_fullImageURL(for: token)))
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

    private static func mcvc_fullImageURL(for token: MCSCfOssTokenResponse) -> String {
        let key = token.objectPath.trimmingCharacters(in: .whitespacesAndNewlines)
        var base = token.uploadTargetUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else { return key }
        guard !key.isEmpty else { return base }
        if base.hasSuffix(key) || base.hasSuffix("/" + key) {
            return base
        }
        while base.hasSuffix("/") {
            base.removeLast()
        }
        let path = key.hasPrefix("/") ? String(key.dropFirst()) : key
        return base + "/" + path
    }

    private static func mcvc_normalizedEndpoint(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
