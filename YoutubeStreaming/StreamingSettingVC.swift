//
//  StreamingSettingVC.swift
//  YoutubeStreaming
//
//  Created by Su PenLi on 2018/1/3.
//  Copyright © 2018年 Su PenLi. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import GoogleSignIn
import SVProgressHUD
import AVFoundation
import HaishinKit


class StreamingSettingVC: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource{
 
    @IBOutlet var streamingSettingView: StreamingSettingView!
    var qualitySetting:[String]!
    var user:GIDGoogleUser!
    var rtmpConnection : RTMPConnection!
    var rtmpStream: RTMPStream!
    var broadcastsId : String!
    var isLive:Bool = false
    var streamName:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44_100)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        
        self.setUpUI()
        
        
       

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        let lfView = self.streamingSettingView.streamView.subviews[0] as! LFView
        lfView.frame = self.streamingSettingView.streamView.bounds
    }
    
    override var shouldAutorotate: Bool{
        return !isLive
    }
    
    func setUpUI(){
        // Title
        let now = Date()
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        self.streamingSettingView.tittleTextField.text = dformatter.string(from: now)
        
        // Quality Setting
        let pickerView = UIPickerView.init()
        pickerView.delegate = self
        pickerView.dataSource = self
        self.streamingSettingView.qualityTextField.text = qualityOption.low.rawValue
        self.streamingSettingView.qualityTextField.inputView = pickerView
        
        // IndexText
        
        self.streamingSettingView.indexTextView.text = user.profile.name + "的直播"
        
        // QualitySetting
        
        let modelName = UIDevice.current.modelName
        let code = modelName.index(modelName.startIndex, offsetBy: 8)
        
        if modelName.substring(to: code) == "iPhone 5"{
            qualitySetting = [qualityOption.veryLow.rawValue,qualityOption.medium.rawValue]
        }else{
            qualitySetting = [qualityOption.veryLow.rawValue,qualityOption.low.rawValue,qualityOption.medium.rawValue,qualityOption.height.rawValue]
        }
        
        // 
        self.creatStreamView()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.streamingSettingView.streamView.subviews[0].removeFromSuperview()
        self.creatStreamView()
    }
    
    func creatStreamView(){
        
        self.rtmpConnection = RTMPConnection()
        self.rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print(error)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: .back)) { error in
            print(error)
        }
        
        rtmpStream.captureSettings = [
            "fps": 30, // FPS
            "sessionPreset": AVCaptureSession.Preset.hd1280x720, // input video width/height
            "continuousAutofocus": true, // use camera autofocus mode
            "continuousExposure": false //  use camera exposure mode
        ]
        rtmpStream.audioSettings = [
            "muted": false, // mute audio
            "bitrate": 32 * 1024,
            "sampleRate": 44_100
        ]
        rtmpStream.videoSettings = [
            "width": 720,
            "height": 1280,
            "bitrate":5000*1024
        ]
        var avVideoCodecKey = ""
        if #available(iOS 11.0, *) {
            avVideoCodecKey = AVVideoCodecType.h264.rawValue
        }else{
            avVideoCodecKey = AVVideoCodecH264
        }
        rtmpStream.recorderSettings = [
            AVMediaType.audio: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 0,
                AVNumberOfChannelsKey: 0,
                // AVEncoderBitRateKey: 128000,
            ],
            AVMediaType.video: [
                AVVideoCodecKey: avVideoCodecKey,
                AVVideoHeightKey: 0,
                AVVideoWidthKey: 0,
            ]
        ]
        let lfView = LFView(frame: self.streamingSettingView.streamView.bounds)
        lfView.videoGravity = AVLayerVideoGravity.resizeAspect
        lfView.attachStream(rtmpStream)
        self.streamingSettingView.streamView.addSubview(lfView)
    }
    
    func transStreamState(state:streamState){
        switch state {
        case .end:
            self.isLive = false
            self.streamingSettingView.qualityTextField.isEnabled = true
            self.streamingSettingView.streamBtn.isEnabled = true
            self.streamingSettingView.shareBtn.isEnabled = false
            self.streamingSettingView.indexTextView.isEditable = true
            self.streamingSettingView.tittleTextField.isEnabled = true
            self.streamingSettingView.streamBtn.setTitle("StartSteaming", for: UIControlState.normal)
            SVProgressHUD.showInfo(withStatus: "結束直播")
        case .live:
            self.isLive = true
            self.streamingSettingView.qualityTextField.isEnabled = false
            self.streamingSettingView.streamBtn.isEnabled = true
            self.streamingSettingView.shareBtn.isEnabled = true
            self.streamingSettingView.indexTextView.isEditable = false
            self.streamingSettingView.tittleTextField.isEnabled = false
            SVProgressHUD.showSuccess(withStatus: "Live...")
            SVProgressHUD.dismiss(withDelay: 0.5)
            self.streamingSettingView.streamBtn.setTitle("EndStreaming", for: UIControlState.normal)
        case .startting:
            self.isLive = true
            self.streamingSettingView.qualityTextField.isEnabled = false
            self.streamingSettingView.streamBtn.isEnabled = false
            self.streamingSettingView.shareBtn.isEnabled = false
            self.streamingSettingView.indexTextView.isEditable = false
            self.streamingSettingView.tittleTextField.isEnabled = false
            self.streamingSettingView.streamBtn.setTitle("Startting Streaming...", for: UIControlState.normal)
        }
    }
    
    //MARK : - PickerView Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return qualitySetting.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return qualitySetting[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.streamingSettingView.qualityTextField.text = qualitySetting[row]
    }
    
    //MARK : - IBAction
    
    @IBAction func shareBtnAction(_ sender: Any) {
        let url = URL.init(string: "https://www.youtube.com/watch?v="+self.broadcastsId)!
        let active = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
        self.present(active, animated: true, completion: nil)
    }
    
    @IBAction func switchBtnAction(_ sender: UIButton) {
        if sender.tag == 0{
            rtmpStream.attachCamera(DeviceUtil.device(withPosition: .front))
            sender.tag = 100
        }else {
            rtmpStream.attachCamera(DeviceUtil.device(withPosition: .back))
            sender.tag = 0
        }
    }
    
    @IBAction func startStreaming(_ sender: Any) {
        
        let domainUrl = "https://www.googleapis.com/youtube/v3"
        let token = self.user.authentication.accessToken!
        func creatStreams(token:String, callBack:@escaping (String)->()){
            let url = URL.init(string: domainUrl + "/liveStreams?part=id,cdn,snippet,contentDetails,status&access_token=\(token)")!
            let par = StreamsItems()
            par.snippet.title = self.streamingSettingView.tittleTextField.text!
            par.cdn.resolution = "variable"
            par.cdn.frameRate = "variable"
            par.cdn.ingestionType = "rtmp"
            par.status.streamStatus = "ready"
            
            Alamofire.request(url, method: .post, parameters: par.toJSON(), encoding: JSONEncoding.default).responseObject { (response: DataResponse<StreamsRes>) in
                
                switch response.result {
                case .success(let value):
                    if value.id != ""{
                        print("Stream：")
                        print(value.id)
                        print(value.cdn.ingestionInfo.streamName)
                        self.streamName = value.cdn.ingestionInfo.streamName
                        callBack(value.id)
                    }else{
                        callBack("-1")
                    }
                case .failure(let fail):
                    print(fail.localizedDescription)
                }
            }
        }
        
        func bindBroadcasts(token:String,id:String,streamId:String , callBack:@escaping (Bool)->()){
            
            let url = URL.init(string: domainUrl + "/liveBroadcasts/bind?id=\(id)&streamId=\(streamId)&part=id,snippet,contentDetails,status&access_token=\(token)")!
            Alamofire.request(url, method: .post).responseObject { (response:DataResponse<BroadcastsRes>) in
                switch response.result {
                case .success(let value):
                    
                    if value.id == id {
                        callBack(true)
                    }else{
                        callBack(false)
                    }
                case .failure(let fail):
                    print(fail.localizedDescription)
                }
            }
        }
        
        func turnToLive(){
            checkBroadcastsStatus(broadcastsId: self.broadcastsId) { (status) in
                print("Broadcasts Status: \(status)")
                switch status {
                case "ready":
                    SVProgressHUD.showProgress(0.6, status: "Ready...")
                    transitionBroadcasts(token: self.user.authentication.accessToken, id: self.broadcastsId, status: .testing)
                case "testStarting":
                    SVProgressHUD.showProgress(0.7, status: "testStarting...")
                case "testing":
                    SVProgressHUD.showProgress(0.8, status: "Testing...")
                    transitionBroadcasts(token: self.user.authentication.accessToken, id: self.broadcastsId, status: .live)
                case "liveStarting":
                    SVProgressHUD.showProgress(0.9, status: "liveStarting...")
                case "live":
                    self.transStreamState(state: .live)
                default:
                    SVProgressHUD.showError(withStatus: "\(status)")
                    break
                }
                if status != "live" {
                    turnToLive()
                }
            }
        }
        
        func checkStream(streamId:String){
            checkStreamStatus(streamId: streamId, callBack: { (isActive) in
                if isActive{
                    turnToLive()
                    print("轉換testing.........")
                }else{
                    checkStream(streamId: streamId)
                }
            })
        }
        
        func checkStreamStatus(streamId:String ,callBack:@escaping (Bool)->()){
            let url = URL.init(string: domainUrl + "/liveStreams?id=\(streamId)&part=id,snippet,status&access_token=\(token)")!
            Alamofire.request(url, method: .get).responseObject { (response:DataResponse<StreamsReq>) in
                switch response.result {
                case .success(let value):
                    print("Stream狀態：\((value.items.first?.status.streamStatus)!)")
                    if (value.items.first?.status.streamStatus) == "active"{
                        callBack(true)
                    }else if (value.items.first?.status.streamStatus) == "inactive"{
                        SVProgressHUD.showInfo(withStatus: "Stream Inactive")
                        break
                    }else{
                        callBack(false)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        func checkBroadcastsStatus(broadcastsId:String,callBack:@escaping (String)->()){
            
            let url = URL.init(string: domainUrl + "/liveBroadcasts?part=id,snippet,contentDetails,status&id=\(broadcastsId)&access_token=\(token)")!
            Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseObject { (response:DataResponse<Broadcasts>) in
                switch response.result{
                case .success(let value):
                    if value.items.count != 0 {
                        callBack((value.items.first?.status.lifeCycleStatus)!)
                    }else{
                        callBack("")
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        func transitionBroadcasts(token:String , id:String ,status:TransitionStatus ){
            let url = URL.init(string: domainUrl + "/liveBroadcasts/transition?id=\(id)&broadcastStatus=\(status)&part=id,snippet,contentDetails,status&access_token=\(token)")!
            Alamofire.request(url, method: .post)
        }
        func creatBroadcasts(token:String , callBack:@escaping (String)->()){
            let url = URL.init(string: domainUrl + "/liveBroadcasts?part=id,snippet,contentDetails,status&access_token=\(token)")!
            
            let par = BroadcastsItems()
            par.snippet.scheduledStartTime = Date().iso8601
            par.snippet.title = self.streamingSettingView.tittleTextField.text!
            par.snippet.description = self.streamingSettingView.indexTextView.text!
            par.status.privacyStatus = "public"
            par.status.lifeCycleStatus = "created"
            
            Alamofire.request(url, method: .post, parameters: par.toJSON(), encoding: JSONEncoding.default).responseObject { (response: DataResponse<BroadcastsRes>) in
                switch response.result {
                case .success(let value):
                    if value.id != ""{
                        self.broadcastsId = value.id
                        callBack(value.id)
                    }else{
                        callBack("-1")
                    }
                case .failure(let fail):
                    print(fail.localizedDescription)
                }
            }
        }
        
        
        if !isLive {
            transStreamState(state: .startting)
            if UIDevice.current.orientation.isPortrait{
                rtmpStream.videoSettings = [
                    "width": 720,
                    "height": 1280,
                    "bitrate":5000*1024
                ]
            }else{
                rtmpStream.videoSettings = [
                    "width": 1280,
                    "height": 720,
                    "bitrate":5000*1024
                ]
            }
            
            SVProgressHUD.showProgress(0.2, status: "creatBroadcasts&creatStreams")
            creatBroadcasts(token: self.user.authentication.accessToken, callBack: { (broadcastsId) in
                creatStreams(token: self.user.authentication.accessToken, callBack: { (streamId) in
                    if broadcastsId != "-1" && streamId != "-1"{
                        SVProgressHUD.showProgress(0.4, status: "bindBroadcasts")
                        bindBroadcasts(token: self.user.authentication.accessToken, id: broadcastsId, streamId: streamId, callBack: { (success) in
                            if success{
                                SVProgressHUD.showProgress(0.5, status: "bindBroadcasts success")
                                self.rtmpConnection.connect("rtmp://x.rtmp.youtube.com/live2/\(self.streamName!)")
                                self.rtmpStream.publish(self.streamName!, type: .live)
                                checkStream(streamId: streamId)
                            }else{
                                SVProgressHUD.showInfo(withStatus: "FailBindBroadcasts")
                            }
                        })
                    }else{
                        SVProgressHUD.showInfo(withStatus: "Fail creatBroadcasts&creatStreams")
                        GIDSignIn.sharedInstance().scopes = []
                        GIDSignIn.sharedInstance().signOut()
                    }
                })
            })
        }else{
            transitionBroadcasts(token: self.user.authentication.accessToken, id: self.broadcastsId, status: .complete)
            self.transStreamState(state: .end)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SVProgressHUD.show(withStatus: "didReceiveMemoryWarning")
    }
    
    enum TransitionStatus {
        case complete
        case testing
        case live
    }
    enum qualityOption:String{
        case veryLow = "720P,30FPS"
        case low = "720P,60FPS"
        case medium = "1080p,30FPS"
        case height = "1080p,60FPS"
        case veryHeight = "2k,30FPS"
        case ultra = "4k,30FPS"
    }
    enum streamState{
        case end
        case startting
        case live
    }

}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

