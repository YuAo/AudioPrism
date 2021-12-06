//
//  File.swift
//
//

import SwiftUI
import AVFoundation
import AudioPrism
import Fixtures

class AudioPrismDemoController: ObservableObject {
    
    @Published private(set) var image: CGImage?

    private let audioEngine = AVAudioEngine()
    private let playerNode: AVAudioPlayerNode
    private let audioFile: AVAudioFile
    
    private let renderContext: CGContext = CGContext(data: nil, width: 512, height: 256, bitsPerComponent: 8, bytesPerRow: 512 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)!

    init(audioURL: URL) throws {
        let options = AudioPrism.Options(fftSize: 2048, maxDecibels: 0)
        let prism = try AudioPrism(options: options)
        let playerNode = AVAudioPlayerNode()
        self.playerNode = playerNode
        let audioFile = try AVAudioFile(forReading: audioURL, commonFormat: .pcmFormatFloat32, interleaved: false)
        self.audioFile = audioFile
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: audioFile.processingFormat) { buffer, time in
            buffer.frameLength = 1024
            do {
                try prism.update(with: buffer)
                if let data = prism.frequencyData {
                    DispatchQueue.main.async {
                        self.update(buffer: data.uint8Values)
                    }
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        try audioEngine.start()
        restart()
    }
    
    func restart() {
        playerNode.stop()
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
        playerNode.play()
    }
    
    private func update(buffer: [UInt8]) {
        let context = renderContext
        let width = renderContext.width
        let height = renderContext.height
        
        context.setFillColor(CGColor.black)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        let fftBinCount = min(buffer.count, 512) //This demo uses the lower frequency bins only
        let bars = 64
        let samplesInBar = (fftBinCount / bars)
        let barWidth: CGFloat = CGFloat(width) / CGFloat(bars)
        
        for i in 0..<bars {
            let start = Int(floor(Float(fftBinCount) / Float(bars) * Float(i)))
            let value = buffer[start..<(start + samplesInBar)].map({ CGFloat($0) / 255.0 }).reduce(0, +) / CGFloat(samplesInBar)
            let r = value
            let g = 4.0 * value * (1.0 - value)
            let b = 1.0 - value
            let h = max(2, value * CGFloat(height))
            context.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: 1))
            let rect = CGRect(x: CGFloat(i) * barWidth, y: 0, width: barWidth * 0.9, height: h)
            context.fill(rect)
        }
        self.image = context.makeImage()
    }
}

struct AudioPrismDemoView: View {
    @StateObject var controller: AudioPrismDemoController = try! AudioPrismDemoController(audioURL: Fixtures.audioURL)
    
    var body: some View {
        if let image = controller.image {
            Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                .toolbar(content: {
                    Button("Restart", action: { [controller] in
                        controller.restart()
                    })
                })
        } else {
            Text("Loading...").frame(width: 512, height: 256)
        }
    }
}

// MARK: - Application Support

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct AudioPrismDemo: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            AudioPrismDemoView()
        }
    }
}

AudioPrismDemo.main()

