//
//  SetCell.swift
//  SetCardDetector
//
//  Created by Grace Tang on 8/2/22.
//

import UIKit

class SetCell: UICollectionViewCell {

    @IBOutlet weak var cardOneDesc: UILabel!
    @IBOutlet weak var cardTwoDesc: UILabel!
    @IBOutlet weak var cardThreeDesc: UILabel!
    
    var cardOne: SetCard? = nil
    var cardTwo: SetCard? = nil
    var cardThree: SetCard? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

}
