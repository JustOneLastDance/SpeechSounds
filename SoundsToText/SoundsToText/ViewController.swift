//
//  ViewController.swift
//  SoundsToText
//
//  Created by JustinChou on 16/10/25.
//  Copyright © 2016年 JustinChou. All rights reserved.
//

/*
 1. 苹果公司对每个设备的识别功能都有一定的限制，可咨询苹果公司
 2. 苹果公司对每个app也有识别功能限制
 3. 如果经常遇到限制，请一定联系苹果公司，他们可以提供解决方案
 4. 语音识别会很耗电以及会使用很多数据
 5. 语音识别一次只持续大概一分钟的时间
 
 */

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
        
        // 检查 recognitionTask 是否在运行，若在则取消任务
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 创建一个 AVAudioSession 对象来记录语音 设置属性时会抛出一场 因此需要放进 try-catch 语句中
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        // 实例化 recognitionRequest 之后需要使用它把语音数据传到苹果后台
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 检查 audioEngine 是否有录音功能的语音输入
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        // 检查 recognitionRequest 是否初始化完毕
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // 当用户说话的时候，让recognitionRequest 输出部分语音识别的结果
        recognitionRequest.shouldReportPartialResults = true;
        
        // 调用 speechRecognizer 的 recognitionTask 方式来开启语音识别
        // 有个完成回调 每次会在识别引擎收到输入的时候，完善了当前识别的信息时候，或者被删除或者停止的时候被调用，最后会返回一个最终的文本
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                // 如果 result 不是 nil，那么就将语音识别的最优结果输出，设置 isFinal 为 true
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                // 如果没有错误，或者结果时最终结果的话，停止request&task， 同时使识别按钮生效
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
            }
        })
        
        // 向 recognitionRequest 增加一个语音输入
        // **在开始的 recognitionTask 之后增加语音输入是可行的**
        // Speech Framework 会在语音输入被加入的同时就开始进行语音识别
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        // 准备并且开始 audioEngine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
            
        textView.text = "Say Something, I'm listening!"
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    

    @IBAction func microphoneTapped(_ sender: AnyObject) {
        print("click the button")
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
}


