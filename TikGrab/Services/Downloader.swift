import Foundation
import Photos
import UIKit

final class Downloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Double = 0
    @Published var isDownloading: Bool = false
    @Published var statusText: String = ""
    @Published var lastDownloadedFile: URL?

    private var session: URLSession?
    private var completion: ((Result<URL, Error>) -> Void)?
    private var isVideo: Bool = true

    func download(from urlString: String, isVideoFile: Bool, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        self.completion = completion
        self.isVideo = isVideoFile
        DispatchQueue.main.async {
            self.progress = 0
            self.isDownloading = true
            self.statusText = "Downloading..."
        }
        let config = URLSessionConfiguration.default
        let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session = s
        var req = URLRequest(url: url)
        req.setValue("TikGrab/1.0", forHTTPHeaderField: "User-Agent")
        s.downloadTask(with: req).resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let ext = isVideo ? "mp4" : "mp3"
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("tikgrab-\(UUID().uuidString).\(ext)")
        // Also copy to Documents for MP3 persistence
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            if !isVideo {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let docDest = docs.appendingPathComponent(dest.lastPathComponent)
                try? FileManager.default.copyItem(at: dest, to: docDest)
            }
            DispatchQueue.main.async {
                self.isDownloading = false
                self.progress = 1.0
                self.lastDownloadedFile = dest
            }
            completion?(.success(dest))
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
            completion?(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async { self.progress = p }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.statusText = "Download failed: \(error.localizedDescription)"
            }
            completion?(.failure(error))
        }
    }

    static func saveVideoToPhotos(fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TikGrab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photos permission denied. Allow it in Settings > TikGrab > Photos."])))
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? NSError(domain: "TikGrab", code: 2, userInfo: [NSLocalizedDescriptionKey: "Saving to Photos failed."])))
                    }
                }
            }
        }
    }
}
