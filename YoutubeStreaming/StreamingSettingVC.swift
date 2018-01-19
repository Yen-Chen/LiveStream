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


class StreamingSettingVC: UIViewController {

    @IBOutlet var streamingSettingView: StreamingSettingView!
    var authentication:GIDAuthentication!
    var broadcastsId:String?
    var streamId:String?
    var streamName:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        
        let now = Date()
        
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        print("当前日期时间：\(dformatter.string(from: now))")
        
        self.streamingSettingView.tittleTextField.text = dformatter.string(from: now)
    }
    @IBAction func startStreaming(_ sender: Any) {
    
        let auth = authentication!
        let accessToken = auth.accessToken!
        print(accessToken)
        SVProgressHUD.showProgress(0.2, status: "creatBroadcasts&creatStreams")
//        SVProgressHUD.showInfo(withStatus: "creatBroadcasts&creatStreams")
        self.creatBroadcasts(token: accessToken, callBack: { (broadcastsId) in
            self.creatStreams(token: accessToken, callBack: { (streamId) in
                if broadcastsId != "-1" && streamId != "-1"{
                    SVProgressHUD.showProgress(0.4, status: "bindBroadcasts")
//                    SVProgressHUD.showInfo(withStatus: "bindBroadcasts")
                    self.bindBroadcasts(token: auth.accessToken, id: broadcastsId, streamId: streamId, callBack: { (success) in
                        
                        if success{
                            
                                //連接rtmp後轉換狀態 -> testing -> wait -> live
                            SVProgressHUD.showInfo(withStatus: "BindBroadcasts success")
                            self.performSegue(withIdentifier: "gotoStreamingVCID", sender: nil)
                            
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

    }
    func creatBroadcasts(token:String , callBack:@escaping (String)->()){
        
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id,snippet,contentDetails,status&access_token=\(token)")
        
        let par = BroadcastsItems()
        par.snippet.scheduledStartTime = Date().iso8601

        par.snippet.title = self.streamingSettingView.tittleTextField.text!
        par.snippet.description = self.streamingSettingView.indexTextView.text!
        par.status.privacyStatus = "public"
        par.status.lifeCycleStatus = "created"
        

        Alamofire.request(url!, method: .post, parameters: par.toJSON(), encoding: JSONEncoding.default).responseObject { (response: DataResponse<BroadcastsRes>) in

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
    
    func creatStreams(token:String, callBack:@escaping (String)->()){
        
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveStreams?part=id,cdn,snippet,contentDetails,status&access_token=\(token)")
        
        let par = StreamsItems()
        par.snippet.title = "StreamTest"
        par.cdn.format = "720p"
        par.cdn.ingestionType = "rtmp"
        par.status.streamStatus = "ready"
            
        Alamofire.request(url!, method: .post, parameters: par.toJSON(), encoding: JSONEncoding.default).responseObject { (response: DataResponse<StreamsRes>) in
            
            switch response.result {
            case .success(let value):
                if value.id != ""{
                    print("Stream：")
                    print(value.id)
                    print(value.cdn.ingestionInfo.streamName)
                    self.streamId = value.id
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
        
        let url = URL.init(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts/bind?id=\(id)&streamId=\(streamId)&part=id,snippet,contentDetails,status&access_token=\(token)")
        
        Alamofire.request(url!, method: .post).responseObject { (response:DataResponse<BroadcastsRes>) in
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
    
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoStreamingVCID"{
            let vc = segue.destination as! StreamingVC
            vc.authentication = self.authentication
            vc.broadcastsId = self.broadcastsId
            vc.streamName = self.streamName
            vc.streamId = self.streamId
        }
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
