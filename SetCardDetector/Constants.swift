//
//  Constants.swift
//  SetCardDetector
//
//  Created by Grace Tang on 7/27/22.
//

import Foundation

struct K {
    struct Card {
        static let NUM_DICT = ["0": "1", "1": "2", "2": "3"]
        static let COLOR_DICT = ["0": "red", "1": "green", "2": "purple"]
        static let FILL_DICT = ["0": "full", "1": "empty", "2": "striped"]
        static let SHAPE_DICT = ["0": "oval", "1": "diamond", "2": "squiggle"]
    }
    
    static let cellNibName = "SetCell"
    static let cellIdentifier = "setCell"
    
    struct Info {
        static let tutorial = "Take a picture of your SET cards with your camera or upload an image. Make sure your cards are arranged vertically (short sides on the top and bottom) with no overlap. See example below: "
    }
}

// Probably doesn't belong here, but I wasn't really sure where it should go
// Extends the String class to include subscripting (i.e. string[0])
extension String {
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}
