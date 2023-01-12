//
//  SetSolver.swift
//  SetCardDetector
//
//  Created by Grace Tang on 7/27/22.
//

import Foundation
import Vision

struct SetSolver {
    
    func createCard(id: String, _ box: CGRect) -> SetCard? {
        if id.count != 4 {
            return nil
        }
        return SetCard(number: Int(id[0]) ?? 0, color: Int(id[1]) ?? 0, fill: Int(id[2]) ?? 0, shape: Int(id[3]) ?? 0, boundingBox: box)
    }
    
    func getCardsFromDetections(detections: [VNRecognizedObjectObservation]) -> [SetCard] {
        var cards: [SetCard] = []
        for detection in detections {
            let id = detection.labels.first!.identifier
            let boundingBox = detection.boundingBox
            if let card = createCard(id: id, boundingBox) {
                cards.append(card)
            }
        }
        return cards
    }
    
    // Checks to see whether three given SetCards form a set
    func isSet(_ c1: SetCard, _ c2: SetCard, _ c3: SetCard) -> Bool {
        // if numbers, colors, fill or shape all same or different
        let n_sd = ((c1.num + c2.num + c3.num) % 3) == 0
        let c_sd = ((c1.color + c2.color + c3.color) % 3) == 0
        let f_sd = ((c1.fill + c2.fill + c3.fill) % 3) == 0
        let s_sd = ((c1.shape + c2.shape + c3.shape) % 3) == 0
        return n_sd && c_sd && f_sd && s_sd
    }
    
    func solve(_ board: [SetCard]) -> [[SetCard]]{
        let num_cards = board.count
        var sets: [[SetCard]] = []
        
        if num_cards < 3 {
            return sets
        }
        
        for first_card in 0..<num_cards-2 {
            for second_card in first_card+1..<num_cards-1 {
                for third_card in second_card+1..<num_cards {
                    let c1 = board[first_card]
                    let c2 = board[second_card]
                    let c3 = board[third_card]
                    
                    if isSet(c1, c2, c3) {
                        sets.append([c1, c2, c3])
                    }
                }
            }
        }
        return sets
    }
}
