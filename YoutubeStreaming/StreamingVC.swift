//
//  StreamingVC.swift
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
import SVProgressHUD

enum TransitionStatus {
    case complete
    case testing
    case live
}

class StreamingVC: UIViewController {
    
    var rtmpStream: RTMPStream!
    var rtmpConnection : RTMPConnection!
    var authentication:GIDAuthentication!
    var broadcastsId:String!
    var streamName:String?
    var streamId : String!
    var isLive:Bool = false
    @IBOutlet weak var streamingView: UIView!
    
    @IBOutlet weak var endStreamingBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44_100)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        
        SVProgressHUD.showProgress(0.5, status: "try to open streaming...")
//        SVProgressHUD.showInfo(withStatus: "try to open streaming...")
        self.creatStreamView()
        
        self.rtmpConnection.connect("rtmp://x.rtmp.youtube.com/live2/\(self.streamName!)")
        self.rtmpStream.publish(self.streamName!, type: .live)
        
        self.checkStream(streamId: streamId)
        
        // Do any additional setup after loading the view.
    }
    
    func turnToLive(){
        self.checkBroadcastsStatus(broadcastsId: self.broadcastsId) { (status) in
            print("Broadcasts Status: \(status)")
            switch status {
            case "ready":
                SVProgressHUD.showProgress(0.6, status: "Ready...")
                self.transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .testing)
            case "testStarting":
                SVProgressHUD.showProgress(0.7, status: "testStarting...")
            case "testing":
                SVProgressHUD.showProgress(0.8, status: "Testing...")
                self.transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .live)
            case "liveStarting":
                SVProgressHUD.showProgress(0.9, status: "liveStarting...")
            case "live":
                self.isLive = true
                self.endStreamingBtn.isEnabled = true
                
                SVProgressHUD.showSuccess(withStatus: "Live...")
                SVProgressHUD.dismiss(withDelay: 1.0)
            default:
                SVProgressHUD.showError(withStatus: "\(status)")
                break
            }
            if !self.isLive{
//                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    self.turnToLive()
//                })
            }
        }
        
        
        
    }
    
    func checkStream(streamId:String){
        
        self.checkStreamStatus(streamId: streamId, callBack: { (isActive) in
            if isActive{
                self.turnToLive()
                print("轉換testing.........")
            }else{
                self.checkStream(streamId: streamId)
            }
        })
        
    }
    
    func checkStreamStatus(streamId:String ,callBack:@escaping (Bool)->()){
        
        let token = self.authentication.accessToken!
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveStreams?id=\(streamId)&part=id,snippet,status&access_token=\(token)")
        
        Alamofire.request(url!, method: .get).responseObject { (response:DataResponse<StreamsReq>) in
            
            switch response.result {
            case .success(let value):
                
                print("Stream狀態：\((value.items.first?.status.streamStatus)!)")
                
                if (value.items.first?.status.streamStatus) == "active"{
                    callBack(true)
                }else{
                    callBack(false)
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    func checkBroadcastsStatus(broadcastsId:String,callBack:@escaping (String)->()){
        
        let token = self.authentication.accessToken!
        
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id,snippet,contentDetails,status&id=\(broadcastsId)&access_token=\(token)")
        
        Alamofire.request(url!, method: .get, encoding: JSONEncoding.default).responseObject { (response:DataResponse<Broadcasts>) in
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
            "sessionPreset": AVCaptureSession.Preset.medium, // input video width/height
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
        rtmpStream.recorderSettings = [
            AVMediaType.audio: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 0,
                AVNumberOfChannelsKey: 0,
                // AVEncoderBitRateKey: 128000,
            ],
            AVMediaType.video: [
                AVVideoCodecKey: AVVideoCodecType.h264,
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
        
        
        let lfView: LFView = LFView(frame: self.streamingView.bounds)
        lfView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        lfView.attachStream(rtmpStream)
        self.streamingView.addSubview(lfView)
    }
    
    func transitionBroadcasts(token:String , id:String ,status:TransitionStatus ){
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts/transition?id=\(id)&broadcastStatus=\(status)&part=id,snippet,contentDetails,status&access_token=\(token)")
        Alamofire.request(url!, method: .post)
    }
    
    @IBAction func endStreamingAction(_ sender: Any) {
        self.transitionBroadcasts(token: self.authentication.accessToken, id: self.broadcastsId, status: .complete)
        SVProgressHUD.showInfo(withStatus: "結束直播")
        self.isLive = false
        self.endStreamingBtn.isEnabled = false
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
