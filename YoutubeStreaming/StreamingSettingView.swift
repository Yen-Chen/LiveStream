//
//  StreamingSettingView.swift
//  YoutubeStreaming
//
//  Created by Su PenLi on 2018/1/3.
//  Copyright © 2018年 Su PenLi. All rights reserved.
//

import UIKit

class StreamingSettingView: UIView {

    @IBOutlet weak var tittleTextField: UITextField!
    @IBOutlet weak var indexTextView: UITextView!
    @IBOutlet weak var streamView: UIView!
    @IBOutlet weak var streamBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var qualityTextField: UITextField!
    @IBOutlet weak var turnBtn: UIButton!
    
    override func awakeFromNib() {
        self.indexTextView.layer.cornerRadius = 5
        self.shareBtn.layer.cornerRadius = 5
        self.streamBtn.layer.cornerRadius = 5
        self.turnBtn.layer.cornerRadius = 5
    }
     
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
