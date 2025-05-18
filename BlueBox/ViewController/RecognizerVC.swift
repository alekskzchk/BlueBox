//
//  RecognizerVC.swift
//  BlueBox
//
//  Created by Алексей Козачук on 14.05.2025.
//

import UIKit

final class RecognizerVC: UIViewController, ToneRecognizerDelegate {
    
    private let textView = UITextView()
    private let copyButton = UIButton(configuration: .plain())
    private let startStopButton = UIButton(configuration: .filled())
    private let clearButton = UIButton(configuration: .plain())
    private let persistenceCountLabel = UILabel()
    private let persistenceCountSlider = UISlider()
    private let detectionThresholdLabel = UILabel()
    private let detectionThresholdSlider = UISlider()
    
    private let recognizer = ToneRecognizer()
    
    private lazy var copyStartClearButtonsHStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [copyButton, startStopButton, clearButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    
    private lazy var allVStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [textView, copyStartClearButtonsHStack, persistenceCountLabel, persistenceCountSlider, detectionThresholdLabel, detectionThresholdSlider])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        recognizer.delegate = self
        setupViews()
        setConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupViews() {
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.systemGray.cgColor
        textView.isScrollEnabled = false
        
        copyButton.setTitle("Copy", for: .normal)
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        
        startStopButton.setTitle("Start", for: .normal)
        startStopButton.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        
        clearButton.setTitle("Clear", for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        
        persistenceCountSlider.minimumValue = 0
        persistenceCountSlider.maximumValue = 10
        persistenceCountSlider.value = Float(recognizer.requiredPersistenceCount)
        persistenceCountSlider.addTarget(self, action: #selector(persistenceCountSliderValueChanged(_:)), for: .valueChanged)
        updatePersistenceLabel()
        
        detectionThresholdSlider.minimumValue = 0
        detectionThresholdSlider.maximumValue = 200
        detectionThresholdSlider.value = recognizer.detectionThreshold
        detectionThresholdSlider.addTarget(self, action: #selector(detectionThresholdSliderValueChanged(_:)), for: .valueChanged)
        updateDetectionThresholdLabel()
        
        view.addSubview(allVStack)
    }
    
    private func setConstraints() {
        allVStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalTo: allVStack.widthAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
            persistenceCountSlider.widthAnchor.constraint(equalTo: allVStack.widthAnchor, constant: -20),
            detectionThresholdSlider.widthAnchor.constraint(equalTo: allVStack.widthAnchor, constant: -20),
            allVStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            allVStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            allVStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            allVStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func persistenceCountSliderValueChanged(_ sender: UISlider) {
        recognizer.requiredPersistenceCount = Int(sender.value)
        updatePersistenceLabel()
    }
    
    private func updatePersistenceLabel() {
        persistenceCountLabel.text = "Persistence count \(Int(persistenceCountSlider.value))"
    }
    
    @objc private func detectionThresholdSliderValueChanged(_ sender: UISlider) {
        recognizer.detectionThreshold = Float(sender.value)
        updateDetectionThresholdLabel()
    }
    
    private func updateDetectionThresholdLabel() {
        detectionThresholdLabel.text = String(format: "Detection threshold \(Int(detectionThresholdSlider.value))")
    }
    
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = textView.text
    }
    
    @objc private func startStopButtonTapped() {
        if recognizer.isRunning {
            recognizer.stopRecognition()
            startStopButton.setTitle("Start", for: .normal)
        } else {
            recognizer.startRecognition()
            startStopButton.setTitle("Stop", for: .normal)
        }
    }
    
    @objc private func clearButtonTapped() {
        textView.text = String()
    }
    
    internal func appendToTextView(_ character: Character) {
        textView.text?.append(character)
    }
    
    func showAlert(error: RecognizerError) {
        var title: String {
            switch error {
            case .audioEngineStartFailed:
                return "Audio engine start failed"
            case .permissionDenied:
                return "Permission denied"
            case .unknownInputFormat:
                return "Unknown input format"
            }
        }
        var message: String {
            switch error {
            case .audioEngineStartFailed:
                return "Audio engine start failed"
            case .permissionDenied:
                return "Please grant permission to use the microphone in Settings > Privacy > Microphone"
            case .unknownInputFormat:
                return "Try unplugging external audio device or check permissions in Settings > Privacy > Microphone"
            }
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recognizer.stopRecognition()
        startStopButton.setTitle("Start", for: .normal)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
