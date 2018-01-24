//
//  NavigationController.swift
//  YoutubeStreaming
//
//  Created by Reaper on 2018/1/24.
//  Copyright © 2018年 Su PenLi. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var shouldAutorotate: Bool {
        guard let topViewController = topViewController else {
            return true
        }
        return topViewController.shouldAutorotate
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
