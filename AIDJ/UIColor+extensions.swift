//
//  UIColor+extensions.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/03/10.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit

extension UIColor {
    
    struct Jadia {
        /** #6DC3C4 */
        static let coolCyan: UIColor = #colorLiteral(red: 0.4274509804, green: 0.7647058824, blue: 0.768627451, alpha: 1)
        /** #606060 */
        static let gray: UIColor = #colorLiteral(red: 0.3764705882, green: 0.3764705882, blue: 0.3764705882, alpha: 1)
    }
    
    convenience init(rgb: Int) {
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >>  8) / 255.0
        let b = CGFloat( rgb & 0x0000FF       ) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
