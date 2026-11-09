import SwiftUI
import AVKit
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ContentView: View {
    @StateObject private var history = HistoryStore()
    @StateObject private var downloader = Downloader()
    @State private var urlText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorText: String?
    @State private var statusText: String = ""
    @State private var current: TikWMData?
    @State private var currentLink: String = ""
    @State private var player: AVPlayer?
    @State private var showShare: Bool = false
    @State private var shareItems: [Any] = []
    @FocusState private var urlFocused: Bool

    private let pink = Color(red: 254/255, green: 44/255, blue: 85/255)
    private let cyan = Color(red: 37/255, green: 244/255, blue: 238/255)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    inputSection
                    noteCard
                    if isLoading {
                        HStack { ProgressView().tint(cyan); Text("Fetching video...").foregroundColor(.gray) }
                            .frame(maxWidth: .infinity)
                    }
                    if let errorText = errorText {
                        Text(errorText).foregroundColor(.red).font(.subheadline)
                            .padding().frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.12)).cornerRadius(10)
                    }
                    if !statusText.isEmpty {
                        Text(statusText).foregroundColor(cyan).font(.subheadline)
                    }
                    if downloader.isDownloading {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Downloading \(Int(downloader.progress * 100))%").font(.caption).foregroundColor(.gray)
                            ProgressView(value: downloader.progress).tint(pink)
                        }
                    }
                    if let current = current {
                        resultCard(current)
                    }
                    historySection
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .sheet(isPresented: $showShare) {
                ShareSheet(items: shareItems)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3).fill(cyan).frame(width: 8, height: 28)
                RoundedRectangle(cornerRadius: 3).fill(pink).frame(width: 8, height: 28)
                Text("TikGrab").font(.largeTitle).fontWeight(.black).foregroundColor(.white)
            }
            Text("No Watermark Downloader").foregroundColor(.gray).font(.subheadline)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Paste TikTok link here", text: $urlText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(white: 0.12))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .focused($urlFocused)
                Button("Paste") {
                    if let s = UIPasteboard.general.string { urlText = s }
                }
                .foregroundColor(.black).padding(.horizontal, 12).padding(.vertical, 10)
                .background(cyan).cornerRadius(10).fontWeight(.bold)
                if !urlText.isEmpty {
                    Button("Clear") { urlText = ""; current = nil; errorText = nil }
                        .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 10)
                        .background(Color(white: 0.2)).cornerRadius(10)
                }
            }
            Button(action: fetchVideo) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("GET VIDEO").fontWeight(.black)
                }
                .frame(maxWidth: .infinity).padding()
                .background(pink).foregroundColor(.white).cornerRadius(12)
            }
            .disabled(isLoading || urlText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity((isLoading || urlText.isEmpty) ? 0.6 : 1)
        }
    }

    private var noteCard: some View {
        Text("You get the original quality the creator uploaded — most TikToks are 1080p max. No fake 4K upscale.")
            .font(.caption).foregroundColor(.gray)
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(white: 0.08)).cornerRadius(8)
    }

    @ViewBuilder
    private func resultCard(_ data: TikWMData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let cover = data.cover, let u = URL(string: cover) {
                AsyncImage(url: u) { img in img.resizable().scaledToFit() } placeholder: { Color.gray.opacity(0.3).frame(height: 200) }
                    .cornerRadius(12)
            }
            if let player = player {
                VideoPlayer(player: player).frame(height: 420).cornerRadius(12)
            }
            Text(data.title ?? "Untitled").foregroundColor(.white).font(.headline)
            HStack {
                Text(data.author?.nickname ?? "").foregroundColor(cyan)
                if let uid = data.author?.uniqueId { Text("@\(uid)").foregroundColor(.gray) }
                Spacer()
                if let d = data.duration { Text("\(d)s").foregroundColor(.gray) }
            }.font(.subheadline)

            Button { startDownload(url: data.hdURLString, isVideo: true, saveToPhotos: true) } label: {
                Text("HD • No Watermark").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(pink).foregroundColor(.white).cornerRadius(10)
            }
            Button { startDownload(url: data.play, isVideo: true, saveToPhotos: true) } label: {
                Text("SD • No Watermark").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(Color(white: 0.18)).foregroundColor(.white).cornerRadius(10)
            }
            HStack {
                Button { startDownload(url: data.music, isVideo: false, saveToPhotos: false) } label: {
                    Text("MP3 Audio").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(Color(white: 0.18)).foregroundColor(.white).cornerRadius(10)
                }
                Button { startDownload(url: data.wmplay, isVideo: true, saveToPhotos: true) } label: {
                    Text("With Watermark").font(.subheadline).frame(maxWidth: .infinity).padding().background(Color(white: 0.12)).foregroundColor(.gray).cornerRadius(10)
                }
            }
            if let f = downloader.lastDownloadedFile {
                Button {
                    shareItems = [f]
                    showShare = true
                } label: {
                    Text("Share Downloaded File").foregroundColor(cyan).frame(maxWidth: .infinity).padding().background(Color(white: 0.1)).cornerRadius(10)
                }
            }
        }
        .padding().background(Color(white: 0.07)).cornerRadius(14)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your grabs").font(.headline).foregroundColor(.white)
                Spacer()
                if !history.items.isEmpty {
                    Button("Clear All") { history.clearAll() }.foregroundColor(.red).font(.caption)
                }
            }
            if history.items.isEmpty {
                Text("Nothing yet. Paste a link above to grab your first video.").foregroundColor(.gray).font(.caption)
            } else {
                ForEach(history.items) { item in
                    Button { reopen(item) } label: {
                        HStack(spacing: 10) {
                            if let c = item.cover, let u = URL(string: c) {
                                AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.3) }
                                    .frame(width: 54, height: 72).clipped().cornerRadius(6)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).foregroundColor(.white).font(.subheadline).lineLimit(2).multilineTextAlignment(.leading)
                                Text(item.author).foregroundColor(.gray).font(.caption)
                                Text(item.date, style: .date).foregroundColor(.gray).font(.caption2)
                            }
                            Spacer()
                            Button { history.delete(item: item) } label: { Image(systemName: "trash").foregroundColor(.red) }
                        }
                        .padding(8).background(Color(white: 0.08)).cornerRadius(10)
                    }
                }
            }
        }
    }

    private func reopen(_ item: HistoryItem) {
        urlText = item.originalLink
        currentLink = item.originalLink
        fetchVideo()
    }

    private func fetchVideo() {
        let link = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty else { return }
        urlFocused = false
        isLoading = true
        errorText = nil
        statusText = ""
        currentLink = link
        Task {
            do {
                let data = try await APIService.fetch(urlString: link)
                await MainActor.run {
                    self.current = data
                    self.isLoading = false
                    if let best = data.hdURLString, let u = URL(string: best) {
                        self.player = AVPlayer(url: u)
                    } else { self.player = nil }
                    let authorName: String
                    if let n = data.author?.nickname { authorName = n }
                    else if let uid = data.author?.uniqueId { authorName = "@\(uid)" }
                    else { authorName = "" }
                    let hist = HistoryItem(id: data.cover ?? UUID().uuidString, title: data.title ?? "Untitled", author: authorName, cover: data.cover, originalLink: link, date: Date(), playURL: data.play, hdPlayURL: data.hdplay, wmPlayURL: data.wmplay, musicURL: data.music, duration: data.duration)
                    // Use link as stable id to dedupe
                    var h = hist; h.id = link
                    self.history.add(h)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func startDownload(url: String?, isVideo: Bool, saveToPhotos: Bool) {
        guard let url = url, !url.isEmpty else {
            statusText = "That format isn't available for this video."
            return
        }
        statusText = "Downloading..."
        downloader.download(from: url, isVideoFile: isVideo) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let file):
                    if isVideo && saveToPhotos {
                        Downloader.saveVideoToPhotos(fileURL: file) { r in
                            switch r {
                            case .success: statusText = "Saved to Photos ✓ No watermark"
                            case .failure(let e): statusText = "Downloaded, but Photos save failed: \(e.localizedDescription) Use Share to save it."
                            }
                        }
                    } else {
                        statusText = "MP3 saved. Use Share to send / save it."
                        shareItems = [file]
                        showShare = true
                    }
                case .failure(let e):
                    statusText = "Download failed: \(e.localizedDescription)"
                }
            }
        }
    }
}
