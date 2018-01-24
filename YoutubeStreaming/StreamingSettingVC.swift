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

enum TransitionStatus {
    case complete
    case testing
    case live
}

class StreamingSettingVC: UIViewController{
 
    @IBOutlet var streamingSettingView: StreamingSettingView!
    var authentication:GIDAuthentication!
    var broadcastsId : String!
    var streamName:String!
    var rtmpStream: RTMPStream!
    var rtmpConnection : RTMPConnection!
    var isLive:Bool = false
    var lfView:LFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44_100)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        
        let now = Date()
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        self.streamingSettingView.tittleTextField.text = dformatter.string(from: now)

        self.creatStreamView()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        lfView.frame = self.streamingSettingView.streamView.bounds
    }
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        lfView.frame = self.streamingSettingView.streamView.bounds
        
//        rtmpStream.videoSettings = [
//            "width": fromInterfaceOrientation.isPortrait ? 1080:1920,
//            "height": fromInterfaceOrientation.isPortrait ? 1920:1080,
//            "bitrate": 5000*1024
//        ]
    }
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
        let token = self.authentication.accessToken!
        func creatStreams(token:String, callBack:@escaping (String)->()){
            let url = URL.init(string: domainUrl + "/liveStreams?part=id,cdn,snippet,contentDetails,status&access_token=\(token)")!
            let par = StreamsItems()
            par.snippet.title = self.streamingSettingView.tittleTextField.text!
            par.cdn.resolution = self.streamingSettingView.qualitySwitch.isOn ? "1080p":"720p"
            par.cdn.frameRate = "30fps"
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
                    transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .testing)
                case "testStarting":
                    SVProgressHUD.showProgress(0.7, status: "testStarting...")
                case "testing":
                    SVProgressHUD.showProgress(0.8, status: "Testing...")
                    transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .live)
                case "liveStarting":
                    SVProgressHUD.showProgress(0.9, status: "liveStarting...")
                case "live":
                    self.isLive = true
                    self.streamingSettingView.streamBtn.isEnabled = true
                    self.streamingSettingView.shareBtn.isEnabled = true
                    self.streamingSettingView.streamBtn.setTitle("EndStreaming", for: UIControlState.normal)
                    self.streamingSettingView.qualitySwitch.isEnabled = false
                    SVProgressHUD.showSuccess(withStatus: "Live...")
                    SVProgressHUD.dismiss(withDelay: 1.0)
                    
                default:
                    SVProgressHUD.showError(withStatus: "\(status)")
                    break
                }
                if !self.isLive{
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
            
            self.streamingSettingView.streamBtn.isEnabled = false
            self.streamingSettingView.streamBtn.setTitle("Startting Streaming...", for: UIControlState.normal)
            SVProgressHUD.showProgress(0.2, status: "creatBroadcasts&creatStreams")
            creatBroadcasts(token: self.authentication.accessToken, callBack: { (broadcastsId) in
                creatStreams(token: self.authentication.accessToken, callBack: { (streamId) in
                    if broadcastsId != "-1" && streamId != "-1"{
                        SVProgressHUD.showProgress(0.4, status: "bindBroadcasts")
                        bindBroadcasts(token: self.authentication.accessToken, id: broadcastsId, streamId: streamId, callBack: { (success) in
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
            transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .complete)
            SVProgressHUD.showInfo(withStatus: "結束直播")
            self.streamingSettingView.shareBtn.isEnabled = false
            self.isLive = false
        }
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
            "sessionPreset": AVCaptureSession.Preset.hd1920x1080, // input video width/height
            "continuousAutofocus": true, // use camera autofocus mode
            "continuousExposure": true //  use camera exposure mode
        ]
        rtmpStream.audioSettings = [
            "muted": false, // mute audio
            "bitrate": 32 * 1024,
            "sampleRate": 44_100
        ]
        rtmpStream.videoSettings = [
            "width": 1280,
            "height": 720,
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
                /*
                 AVVideoCompressionPropertiesKey: [
                 AVVideoMaxKeyFrameIntervalDurationKey: 2,
                 AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline30,
                 AVVideoAverageBitRateKey: 512000
                 ]
                 */
            ]
        ]
        lfView = LFView(frame: self.streamingSettingView.streamView.bounds)
        lfView.videoGravity = AVLayerVideoGravity.resizeAspect
        lfView.attachStream(rtmpStream)
        self.streamingSettingView.streamView.addSubview(lfView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
