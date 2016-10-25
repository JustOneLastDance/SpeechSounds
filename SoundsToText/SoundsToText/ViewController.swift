//
//  ViewController.swift
//  SoundsToText
//
//  Created by JustinChou on 16/10/25.
//  Copyright © 2016年 JustinChou. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    /// 处理语音识别请求
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// 输出语音识别对象的结果
    var recognitionTask: SFSpeechRecognitionTask?
    
    /// 语音引擎，负责提供语音输入
    let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            OperationQueue.main.addOperation {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
    }

}

extension ViewController {
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true;
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
            
        textView.text = "Say Something, I'm listening!"
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        print("click the button")
        startRecording()
    }
}


