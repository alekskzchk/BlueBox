//
//  ToneRecognizer.swift
//  BlueBox
//
//  Created by Алексей Козачук on 14.05.2025.
//

import AVFoundation
import Accelerate

protocol ToneRecognizerDelegate: AnyObject {
    func appendToTextView(_ character: Character)
    func showAlert(error: RecognizerError)
}

enum RecognizerError {
    case permissionDenied
    case audioEngineStartFailed
    case unknownInputFormat
}

class ToneRecognizer {
    private let audioEngine = AVAudioEngine()
    private var fftSetup: FFTSetup?
    private let bufferSize: Int = 1024
    private var lastDetectedSymbol: Character?
    private var symbolPersistenceCount = 0
    var requiredPersistenceCount = 1
    var detectionThreshold: Float = 3
    public private(set) var isRunning = false
    
    weak var delegate: ToneRecognizerDelegate?

    private let dtmfFrequencies: [Double] = [697, 770, 852, 941, 1209, 1336, 1477, 1633]
    private let dtmfSymbols: [[Character]] = [
        ["1", "2", "3", "A"],
        ["4", "5", "6", "B"],
        ["7", "8", "9", "C"],
        ["*", "0", "#", "D"]
    ]
    
    func startRecognition() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            delegate?.showAlert(error: .permissionDenied)
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            delegate?.showAlert(error: .unknownInputFormat)
            return
        }

        fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(bufferSize))), FFTRadix(kFFTRadix2))

        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.analyze(buffer: buffer, format: inputFormat)
        }

        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            delegate?.showAlert(error: .audioEngineStartFailed)
        }
    }
    
    private func analyze(buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        guard let fftSetup = fftSetup else { return }

        let channelData = buffer.floatChannelData![0]
        var window = [Float](repeating: 0, count: bufferSize)
        var real = [Float](repeating: 0, count: bufferSize / 2)
        var imag = [Float](repeating: 0, count: bufferSize / 2)

        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channelData, 1, window, 1, channelData, 1, vDSP_Length(bufferSize))

        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
        channelData.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize) { typeConvertedData in
            vDSP_ctoz(typeConvertedData, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
        }

        vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2(Float(bufferSize))), FFTDirection(FFT_FORWARD))
        var magnitudes = [Float](repeating: 0.0, count: bufferSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize / 2))

        var detected: [(Double, Float)] = []
        for freq in dtmfFrequencies {
            let index = Int(freq / format.sampleRate * Double(bufferSize))
            if index < magnitudes.count {
                detected.append((freq, magnitudes[index]))
            }
        }

        let significant = detected.filter { $0.1 > detectionThreshold }
        if significant.count < 2 { return }
        let sorted = significant.sorted { $0.1 > $1.1 }
        let freq1 = sorted[0].0
        let freq2 = sorted[1].0

        if let row = dtmfFrequencies.firstIndex(of: min(freq1, freq2)),
           let col = dtmfFrequencies.firstIndex(of: max(freq1, freq2)),
           row < 4, col >= 4 {
            
            let symbol = dtmfSymbols[row][col - 4]

            if symbol == lastDetectedSymbol {
                symbolPersistenceCount += 1
            } else {
                lastDetectedSymbol = symbol
                symbolPersistenceCount = 1
            }
            
            if symbolPersistenceCount >= requiredPersistenceCount {
                DispatchQueue.main.async {
                    self.delegate?.appendToTextView(symbol)
                }
                symbolPersistenceCount = 0
                lastDetectedSymbol = nil
            }
        }
    }

    func stopRecognition() {
        if isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            vDSP_destroy_fftsetup(fftSetup)
            isRunning = false
        }
    }
    
    deinit {
        stopRecognition()
    }
}

