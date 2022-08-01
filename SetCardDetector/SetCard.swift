//
//  SetCard.swift
//  SetCardDetector
//
//  Created by Grace Tang on 7/27/22.
//

import Foundation
import CoreGraphics

struct SetCard: CustomStringConvertible {
    var description: String
    
    let num: Int
    let color: Int
    let fill: Int
    let shape: Int
    let boundingBox: CGRect

    init(number n: Int, color c: Int, fill f: Int, shape s: Int, boundingBox b: CGRect) {
        self.num = n
        self.color = c
        self.fill = f
        self.shape = s
        self.boundingBox = b
        self.description = K.Card.NUM_DICT[String(n)]! + " " + K.Card.COLOR_DICT[String(c)]! + " " + K.Card.FILL_DICT[String(f)]! + " " + K.Card.SHAPE_DICT[String(s)]!
    }
    
}
