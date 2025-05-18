//
//  ViewController.swift
//  BlueBox
//
//  Created by Алексей Козачук on 11.05.2025.
//

import UIKit

final class GeneratorVC: UIViewController, UITextViewDelegate {
    
    let textView = UITextView()
    let pauseLabel = UILabel()
    let toneDurationLabel = UILabel()
    let intertoneGapLabel = UILabel()
    let totalDurationLabel = UILabel()
    let toneDurationStepper = UIStepper()
    let intertoneGapStepper = UIStepper()
    let startButton = UIButton(configuration: .filled())
    let allowedCharacters = CharacterSet(charactersIn: "0123456789*#ABCDabcd ")
    
    let toneSynthesizer = ToneSynthesizer()
    
    private var totalDurationInSeconds: Float = 0.0
    private var toneDurationInMilliseconds: Float = 20.0 {
        didSet {
            toneDurationLabel.text = String(format: "Tone duration %.0f ms", toneDurationInMilliseconds)
        }
    }
    private var intertoneGapInMilliseconds: Float = 20.0 {
        didSet {
            intertoneGapLabel.text = String(format: "Intertone gap %.0f ms", intertoneGapInMilliseconds)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setConstraints()
        textView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private lazy var toneDurationVStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [toneDurationLabel, toneDurationStepper])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 20
        return stack
    }()
    
    private lazy var buttonLabelVStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [totalDurationLabel, startButton])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 20
        return stack
    }()
    
    private lazy var intertoneGapVStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [intertoneGapLabel, intertoneGapStepper])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 20
        return stack
    }()
    
    private lazy var steppersButtonHStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [toneDurationVStack, buttonLabelVStack, intertoneGapVStack])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 30
        return stack
    }()
    
    private lazy var allVStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [pauseLabel, textView, steppersButtonHStack])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    
    private func setupViews() {
        pauseLabel.text = "Enter your prompt below \n Add space for pause"
        pauseLabel.textAlignment = .center
        pauseLabel.numberOfLines = 2
        
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.systemGray.cgColor
        textView.isScrollEnabled = false
        
        toneDurationLabel.text = "Tone duration 20 ms"
        toneDurationLabel.font = UIFont.systemFont(ofSize: 14)
        toneDurationLabel.numberOfLines = 2
        toneDurationLabel.adjustsFontSizeToFitWidth = true
        toneDurationLabel.textAlignment = .center
        
        toneDurationStepper.minimumValue = 20
        toneDurationStepper.maximumValue = 2000
        toneDurationStepper.stepValue = 10
        toneDurationStepper.addTarget(self, action: #selector(toneDurationStepperChanged(_:)), for: .valueChanged)
        
        totalDurationLabel.text = "Total duration 0.00 sec"
        totalDurationLabel.font = UIFont.systemFont(ofSize: 14)
        totalDurationLabel.numberOfLines = 2
        totalDurationLabel.adjustsFontSizeToFitWidth = true
        totalDurationLabel.textAlignment = .center
        
        intertoneGapLabel.text = "Intertone gap 20 ms"
        intertoneGapLabel.font = UIFont.systemFont(ofSize: 14)
        intertoneGapLabel.numberOfLines = 2
        intertoneGapLabel.adjustsFontSizeToFitWidth = true
        intertoneGapLabel.textAlignment = .center
        
        intertoneGapStepper.minimumValue = 20
        intertoneGapStepper.maximumValue = 2000
        intertoneGapStepper.stepValue = 10
        intertoneGapStepper.addTarget(self, action: #selector(intertoneGapStepperChanged(_:)), for: .valueChanged)
        
        startButton.setTitle("Start", for: .normal)
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        
        view.addSubview(allVStack)
    }
    
    private func setConstraints() {
        allVStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalTo: allVStack.widthAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
            allVStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            allVStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            allVStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            allVStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func startButtonTapped() {
        toneSynthesizer.playTones(for: textView.text, duration: toneDurationInMilliseconds, intertoneGap: intertoneGapInMilliseconds)
    }
    
    @objc private func toneDurationStepperChanged(_ sender: UIStepper) {
        toneDurationInMilliseconds = Float(sender.value)
        estimateTotalDuration()
    }
    
    @objc private func intertoneGapStepperChanged(_ sender: UIStepper) {
        intertoneGapInMilliseconds = Float(sender.value)
        estimateTotalDuration()
    }
    
    private func estimateTotalDuration() {
        let symbolCount = textView.text.count
        totalDurationInSeconds = (toneDurationInMilliseconds + intertoneGapInMilliseconds) * Float(symbolCount) / 1000
        let formattedDurationString = String(format: "%.2f", totalDurationInSeconds)
        totalDurationLabel.text = "Total duration \(formattedDurationString) sec"
    }
    
    internal func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let scalar = text.unicodeScalars.first, allowedCharacters.contains(scalar) {
            let uppercased = text.uppercased()
            if let textRange = Range(range, in: textView.text) {
                let updatedText = textView.text.replacingCharacters(in: textRange, with: uppercased)
                textView.text = updatedText
                let position = textView.position(from: textView.beginningOfDocument, offset: range.location + uppercased.count)
                if let pos = position {
                    textView.selectedTextRange = textView.textRange(from: pos, to: pos)
                }
            }
            estimateTotalDuration()
            return false
        }
        estimateTotalDuration()
        return text.isEmpty
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        toneSynthesizer.stopPlayingSession()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
