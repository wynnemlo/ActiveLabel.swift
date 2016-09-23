//
//  ViewController.swift
//  ActiveLabelDemo
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ActiveLabel

extension NSMutableAttributedString {
    func appendString(_ string: String, fontColor: UIColor, font: UIFont, link: String = "") -> NSMutableAttributedString {
    if link.isEmpty {
        self.append(NSAttributedString(string: string, attributes: [
            NSForegroundColorAttributeName: fontColor,
            NSFontAttributeName: font
            ]))
    } else {
        self.append(NSAttributedString(string: string, attributes: [
            NSForegroundColorAttributeName: fontColor,
            NSFontAttributeName: font,
            NSLinkAttributeName: link
            ]))
    }
    return self
}
}

class ViewController: UIViewController {
    
    @IBOutlet weak var someLabel: ActiveLabel!
    let label = ActiveLabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.customize { label in
            label.text = "post postThis is like a @s😬asdfasd @好饿 post @what.-the_fuck with #multiple post like #hashtags and a @userha.ndle . and Links are also supported like and this one: http://optonaut.co.and and"
            label.numberOfLines = 0
            label.lineSpacing = 4
            
            label.textColor = UIColor(red: 102.0/255, green: 117.0/255, blue: 127.0/255, alpha: 1)
            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
            label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
            label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
            label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)
//            label.customColor = UIColor.cyanColor()
//            label.customSelectedColor = UIColor.grayColor()

            label.handleMentionTap { self.alert("Mention", message: $0) }
            label.handleHashtagTap { self.alert("Hashtag", message: $0) }
            label.handleURLTap { self.alert("URL", message: $0.absoluteString) }
            
            label.addCustomTargetText("and")
            label.addCustomTargetText("a")
            label.addCustomFirstFoundTargetText("post")
            label.addCustomFirstFoundTargetText("supported")
            label.addCustomFirstFoundFromBackTargetText("like")
            label.addCustomFirstFoundFromBackTargetText("this")
            label.handleCustomTargetTap{ self.alert("Custom", message: $0) }
        }
        
        label.frame = CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 300)
        view.addSubview(label)
        
        let attributedText = NSMutableAttributedString().appendString("this ", fontColor: UIColor.cyan, font: UIFont.systemFont(ofSize: 14))
                            .appendString("is ", fontColor: UIColor.red, font: UIFont.systemFont(ofSize: 14))
                            .appendString("some ", fontColor: UIColor.green, font: UIFont.systemFont(ofSize: 14))
                            .appendString("text ", fontColor: UIColor.blue, font: UIFont.systemFont(ofSize: 14))
        print(NSRange.init(location: 0, length: attributedText.length))
        attributedText.enumerateAttributes(in: NSRange.init(location: 0, length: attributedText.length) , options: .reverse) { (attr, run, stop) in
            print(attr)
            print(run)
            print("--------------------")
        }
        someLabel.attributedText = attributedText
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alert(_ title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        vc.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }

}

