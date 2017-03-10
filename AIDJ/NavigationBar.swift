//
//  NavigationBar.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/03/08.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        let oldSize:CGSize = super.sizeThatFits(size)
        let newSize:CGSize = CGSize(width: oldSize.width, height: 80)
        return newSize
    }
    
    //サブビューのレイアウトを行うメソッッド
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //ビューに含まれるサブビューを1つずつ取得する。
        for view: UIView in self.subviews {
            if(NSStringFromClass(type(of: view)) == "UIImageView") {
                
                //サブビューのクラスがUIImageViewの場合、Y座標を15にする。
                view.frame.origin.y = 15
            }
        }
    }
}
