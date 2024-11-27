import UIKit
import AVFoundation

final public class AudioViewController: UIViewController {
    // MARK: - Properties
    // auido
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    // auido metering
    private var upBarLayers: [CALayer] = []
    private var downBarLayers: [CALayer] = []
    private let numberOfBars = 30
    private let volumeHalfHeight: CGFloat = 40
    // timer
    private var recordingSeconds: Int = 0
    private var recordingTimer: Timer?
    private var timeTimer: Timer?
    // audio session
    private let audioSession = AVAudioSession.sharedInstance()
    private let audioRecordersettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    // UUID
    private let identifier: UUID = UUID()
    
    // MARK: - UI Components
    // title and buttons
    private var stackView = UIStackView()
    private let titleLabel: UITextField = {
        let textField = UITextField(
            frame: CGRect(origin: .zero, size: CGSize(width: 120, height: 28))
        )
        textField.text = "소리 기록"
        textField.font = UIFont.ownglyphBerry(size: 28)
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    private let cancelButton: UIButton = {
        let button = UIButton(
            frame: CGRect(origin: .zero, size: CGSize(width: 60, height: 21))
        )
        var attributedString = AttributedString(stringLiteral: "취소")
        attributedString.font = UIFont.ownglyphBerry(size: 21)
        attributedString.foregroundColor = UIColor.black
        button.setAttributedTitle(NSAttributedString(attributedString), for: .normal)
        return button
    }()
    private let saveButton: UIButton = {
        let button = UIButton(
            frame: CGRect(origin: .zero, size: CGSize(width: 60, height: 21))
        )
        var attributedString = AttributedString(stringLiteral: "저장")
        attributedString.font = UIFont.ownglyphBerry(size: 21)
        attributedString.foregroundColor = UIColor.black
        button.setAttributedTitle(NSAttributedString(attributedString), for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    // audio metering
    private var meteringBackgroundView: UIView = UIView()
    private var upMeteringView: UIView = UIView()
    private var downMeteringView: UIView = UIView()
    private let audioButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .red
        return button
    }()
    private let audioButtonBackground = {
        let buttonBackground = UIView()
        buttonBackground.layer.borderWidth = 4
        buttonBackground.layer.borderColor = UIColor.gray.cgColor
        buttonBackground.layer.cornerRadius = 30
        
        return buttonBackground
    }()
    private var audioButtonConstraints: [NSLayoutConstraint] = []
    // timer
    private var timeTextLabel: UITextField = {
        let textField = UITextField()
        textField.text = "00:00"
        textField.textColor = .black
        textField.font = UIFont.ownglyphBerry(size: 16)
        
        return textField
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        requestMicrophonePermission()
        setup()
        configureAudioSession()
        configureAddSubviews()
        configureConstraints()
        configureAddActions()
    }
    
    private func setup() {
        view.backgroundColor = .white
        setupBars()
    }
    
    private func setupBars() {
        let width = 300 / numberOfBars - 5
        let barSpacing = 5
        
        for index in 0..<numberOfBars {
            let upMeteringLayer = CALayer()
            upMeteringLayer.backgroundColor = UIColor.orange.cgColor
            upMeteringLayer.frame = CGRect(
                x: index * (width + barSpacing),
                y: Int(volumeHalfHeight),
                width: width,
                height: -2
            )
            upMeteringView.layer.addSublayer(upMeteringLayer)
            upBarLayers.append(upMeteringLayer)
            
            let downMeteringLayer = CALayer()
            downMeteringLayer.backgroundColor = UIColor.mhOrange.cgColor
            downMeteringLayer.frame = CGRect(
                x: index * (width + barSpacing),
                y: 0,
                width: width,
                height: 2
            )
            downMeteringView.layer.addSublayer(downMeteringLayer)
            downBarLayers.append(downMeteringLayer)
        }
    }
    
    private func configureAudioSession() {
        let fileName = "\(identifier).m4a"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentDirectory.appendingPathComponent(fileName)
        
        try? audioSession.setCategory(.record, mode: .default)
        
        audioRecorder = try? AVAudioRecorder(url: audioFileURL, settings: audioRecordersettings)
        audioRecorder?.isMeteringEnabled = true
    }
    
    private func configureAddSubviews() {
        stackView = UIStackView(arrangedSubviews: [cancelButton, titleLabel, saveButton])
        view.addSubview(stackView)
        view.addSubview(meteringBackgroundView)
        view.addSubview(audioButtonBackground)
        audioButtonBackground.addSubview(audioButton)
        view.addSubview(timeTextLabel)
    }
    
    private func configureConstraints() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        titleLabel.setWidthAndHeight(width: 120, height: 28)
        cancelButton.setWidthAndHeight(width: 60, height: 21)
        saveButton.setWidthAndHeight(width: 60, height: 21)
        
        stackView.setCenterX(view: view)
        stackView.setAnchor(
            top: view.topAnchor, constantTop: -10,
            leading: view.leadingAnchor, constantLeading: 25,
            trailing: view.trailingAnchor, constantTrailing: 25,
            height: 120
        )
        
        meteringBackgroundView.backgroundColor = UIColor.mhPink
        meteringBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        meteringBackgroundView.setCenterX(view: view)
        meteringBackgroundView.setAnchor(top: titleLabel.bottomAnchor, constantTop: 24)
        meteringBackgroundView.setWidthAndHeight(width: 320, height: volumeHalfHeight * 2)
        meteringBackgroundView.layer.cornerRadius = 25
        
        upMeteringView.translatesAutoresizingMaskIntoConstraints = false
        meteringBackgroundView.addSubview(upMeteringView)
        upMeteringView.setCenter(view: meteringBackgroundView, offset: CGPoint(x: 0, y: -volumeHalfHeight/2))
        upMeteringView.setWidthAndHeight(width: 300, height: volumeHalfHeight)
        
        downMeteringView.translatesAutoresizingMaskIntoConstraints = false
        meteringBackgroundView.addSubview(downMeteringView)
        downMeteringView.setCenter(view: meteringBackgroundView, offset: CGPoint(x: 0, y: volumeHalfHeight/2))
        downMeteringView.setWidthAndHeight(width: 300, height: volumeHalfHeight)
        
        audioButtonBackground.setAnchor(top: meteringBackgroundView.bottomAnchor, constantTop: 20)
        audioButtonBackground.setCenterX(view: view)
        audioButtonBackground.setWidthAndHeight(width: 60, height: 60)
        
        audioButton.layer.cornerRadius = 24
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButtonConstraints = [
            audioButton.widthAnchor.constraint(equalToConstant: 48),
            audioButton.heightAnchor.constraint(equalToConstant: 48),
            audioButton.centerXAnchor.constraint(equalTo: audioButtonBackground.centerXAnchor),
            audioButton.centerYAnchor.constraint(equalTo: audioButtonBackground.centerYAnchor)
        ]
        NSLayoutConstraint.activate(audioButtonConstraints)
        
        timeTextLabel.setAnchor(
            top: meteringBackgroundView.bottomAnchor, constantTop: 10,
            trailing: meteringBackgroundView.trailingAnchor
        )
        timeTextLabel.setWidthAndHeight(width: 60, height: 16)
    }
    
    private func startRecording() {
        try? audioSession.setActive(true)
        
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task {
                await self?.updateAudioMetering()
            }
        }
        
        timeTimer?.invalidate()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingSeconds += 1
                self?.setTimeLabel(seconds: self?.recordingSeconds)
            }
        }
        
        // audio button to start
        audioButton.layer.cornerRadius = 6
        NSLayoutConstraint.deactivate(audioButton.constraints)
        audioButton.setWidthAndHeight(width: 32, height: 32)
        audioButton.setCenter(view: audioButtonBackground)
        NSLayoutConstraint.activate(audioButton.constraints)
    }
    
    private func stopRecording() {
        try? audioSession.setActive(false)
        
        audioRecorder?.stop()
        timeTimer?.invalidate()
        
        recordingSeconds = 0
        timeTextLabel.text = "00:00"
        
        // audio button to stop
        audioButton.layer.cornerRadius = 24
        NSLayoutConstraint.deactivate(audioButton.constraints)
        audioButton.setWidthAndHeight(width: 48, height: 48)
        audioButton.setCenter(view: audioButtonBackground)
        NSLayoutConstraint.activate(audioButton.constraints)
    }
    
    private func updateAudioMetering() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        
        let decibel = CGFloat(recorder.averagePower(forChannel: 0))
        let baseDecibel: CGFloat = -60.0
        let meteringLevel = pow(10, (decibel - baseDecibel) / 30)
        
        let barHeight = min(meteringLevel, volumeHalfHeight - 4)
        
        for index in 0..<numberOfBars-1 {
            upBarLayers[index].frame = CGRect(
                x: upBarLayers[index].frame.origin.x,
                y: volumeHalfHeight,
                width: upBarLayers[index].frame.width,
                height: -upBarLayers[index+1].frame.height
            )
            
            downBarLayers[index].frame = CGRect(
                x: downBarLayers[index].frame.origin.x,
                y: 0,
                width: downBarLayers[index].frame.width,
                height: downBarLayers[index+1].frame.height
            )
        }
        
        upBarLayers[numberOfBars-1].frame = CGRect(
            x: upBarLayers[numberOfBars-1].frame.origin.x,
            y: volumeHalfHeight,
            width: upBarLayers[numberOfBars-1].frame.width,
            height: barHeight > 2 ? -barHeight : -2
        )
        
        downBarLayers[numberOfBars-1].frame = CGRect(
            x: downBarLayers[numberOfBars-1].frame.origin.x,
            y: 0,
            width: downBarLayers[numberOfBars-1].frame.width,
            height: barHeight > 2 ? barHeight : 2
        )
    }
    
    private func setTimeLabel(seconds recordingSeconds: Int?) {
        guard let recordingSeconds = recordingSeconds else { return }
        let minutes = recordingSeconds / 60
        let seconds = recordingSeconds % 60
        timeTextLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func configureAddActions() {
        addTappedEventToAudioButton()
        addTappedEventToCancelButton()
        addTappedEventToSaveButton()
    }
    
    private func addTappedEventToAudioButton() {
        audioButton.addAction(UIAction { [weak self] _ in
            switch self?.isRecording {
                case true:
                    self?.stopRecording()
                case false:
                    self?.startRecording()
                default: break
            }
            self?.audioButtonBackground.layoutIfNeeded()
            self?.isRecording.toggle()
        }, for: .touchUpInside)
    }
    private func addTappedEventToCancelButton() {
        cancelButton.addAction(
            UIAction { [weak self]_ in
                try? FileManager.default.removeItem(
                    at: self?.audioRecorder?.url ?? FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)[0]
                )
                self?.dismiss(animated: true)
            },
            for: .touchUpInside)
    }
    private func addTappedEventToSaveButton() {
        saveButton.addAction(UIAction { _ in
            self.dismiss(animated: true)
        }, for: .touchUpInside)
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { @Sendable granted in
            if !granted {
                Task { @MainActor in
                    let alert = UIAlertController(
                        title: "Microphone Permission Denied",
                        message: "Please enable microphone access in Settings to use this feature.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
