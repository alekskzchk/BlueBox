//
//  Untitled.swift
//  BlueBox
//
//  Created by Алексей Козачук on 11.05.2025.
//

import AVFoundation

typealias DTMFTone = (Float, Float)

class ToneSynthesizer {
    private let engine = AVAudioEngine()
    private let sampleRate: Double = 44100
    private var sourceNode: AVAudioSourceNode!

    private var phase1 = Float()
    private var phase2 = Float()
    
    private var freq1 = Float()
    private var freq2 = Float()
    
    public private(set) var isPlaying = false
    
    private let toneForCharacter: [Character: DTMFTone] = [
        "0": DTMFTone(1336, 941),
        "1": DTMFTone(1209, 697),
        "2": DTMFTone(1336, 697),
        "3": DTMFTone(1447, 697),
        "4": DTMFTone(1209, 770),
        "5": DTMFTone(1336, 770),
        "6": DTMFTone(1447, 770),
        "7": DTMFTone(1209, 852),
        "8": DTMFTone(1336, 852),
        "9": DTMFTone(1447, 852),
        "*": DTMFTone(1209, 941),
        "#": DTMFTone(1336, 941),
        "A": DTMFTone(1633, 697),
        "B": DTMFTone(1633, 770),
        "C": DTMFTone(1633, 852),
        "D": DTMFTone(1633, 941),
        " ": DTMFTone(0, 0)
    ]
    
     func playTones(for string: String, duration: Float, intertoneGap: Float) {
        guard !isPlaying else { return }
        isPlaying = true
        let characters = Array(string)
        var currentIndex = 0
        let durationTimeInterval = TimeInterval(duration / 1000)
        let intertoneGapTimeInterval = TimeInterval(intertoneGap / 1000)
        
        func playNext() {
            guard currentIndex < characters.count && isPlaying else {
                self.freq1 = 0
                self.freq2 = 0
                self.stopPlayingSession()
                return
            }
            
            let character = characters[currentIndex]
            if let tone = toneForCharacter[character] {
                self.freq1 = tone.0
                self.freq2 = tone.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + durationTimeInterval) {
                self.freq1 = 0
                self.freq2 = 0
                currentIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + intertoneGapTimeInterval) {
                    playNext()
                }
            }
        }
        self.startPlayingSession()
        playNext()
    }
    
    private func startPlayingSession() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let renderBlock: AVAudioSourceNodeRenderBlock = { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            
            let audioBufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            let leftChannel = audioBufferList[0].mData!.assumingMemoryBound(to: Float.self)
            let rightChannel = audioBufferList[1].mData!.assumingMemoryBound(to: Float.self)
            
            let thetaCount1 = 2.0 * Float.pi * self.freq1 / Float(self.sampleRate)
            let thetaCount2 = 2.0 * Float.pi * self.freq2 / Float(self.sampleRate)
            
            for frame in 0..<Int(frameCount) {
                let sample = 0.5 * sin(self.phase1) + 0.5 * sin(self.phase2)
                leftChannel[frame] = sample
                rightChannel[frame] = sample
                self.phase1 += thetaCount1
                self.phase2 += thetaCount2
                if self.phase1 > 2 * Float.pi { self.phase1 -= 2 * Float.pi }
                if self.phase2 > 2 * Float.pi { self.phase2 -= 2 * Float.pi }
            }
            return noErr
        }
        
        sourceNode = AVAudioSourceNode(renderBlock: renderBlock)
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        
        if !engine.isRunning {
            try? engine.start()
        }
    }
    
    func stopPlayingSession() {
        if isPlaying {
            isPlaying = false
            engine.stop()
            engine.disconnectNodeInput(sourceNode)
            engine.detach(sourceNode)
        }
    }
    
    deinit {
        stopPlayingSession()
    }
}
