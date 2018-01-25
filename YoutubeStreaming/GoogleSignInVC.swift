//
//  GoogleSignInVC.swift
//  YoutubeStreaming
//
//  Created by Su PenLi on 2018/1/3.
//  Copyright © 2018年 Su PenLi. All rights reserved.
//

import UIKit
import GoogleSignIn

class GoogleSignInVC: UIViewController,GIDSignInUIDelegate,GIDSignInDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        
        let scope = "https://www.googleapis.com/auth/youtube"
        GIDSignIn.sharedInstance().scopes.append(scope)
        GIDSignIn.sharedInstance().signIn()
        
    }
    //Mark: - GoogleSignIn
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print(error)
        }else{
            self.performSegue(withIdentifier: "gotoStreamingSettingVCID", sender: user)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoStreamingSettingVCID"{
            let vc = segue.destination as! StreamingSettingVC
            let user = sender as! GIDGoogleUser
            vc.user = user
        }
    }
    @IBAction func signInAction(_ sender: Any) {
//        if GIDSignIn.sharedInstance().currentUser != nil {
//            GIDSignIn.sharedInstance().scopes = []
//            GIDSignIn.sharedInstance().signOut()
//        }
        
        let scope = "https://www.googleapis.com/auth/youtube"
        GIDSignIn.sharedInstance().scopes.append(scope)
        GIDSignIn.sharedInstance().signIn()
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
