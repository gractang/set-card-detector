//
//  ViewController.swift
//  SetCardDetector
//
//  Created by Grace Tang on 7/19/22.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var photoImageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    var solver = SetSolver()
      
    lazy var detectionRequest: VNCoreMLRequest = {
            do {
                let model = try best072722(configuration: MLModelConfiguration()).model
                let vnCoreMLModel = try VNCoreMLModel(for: model)
                let request = VNCoreMLRequest(model: vnCoreMLModel) { [weak self] request, error in
                    self?.processDetections(for: request, error: error)
                }
                request.imageCropAndScaleOption = .scaleFill
                return request
            } catch {
                fatalError("failed LOL: \(error)")
            }
        }()
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
    }
    
    // perform detection with detection request
    private func updateDetections(for image: UIImage) {
        let orientation = getCGOrientationFromUIImage(image)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.detectionRequest])
            } catch {
                print("Failed to perform detection.\n\(error.localizedDescription)")
            }
        }
    }
    
    // returns the equivalent CGImagePropertyOrientation given an UIImage.
    // This is required because UIImage.imageOrientation values don't match to CGImagePropertyOrientation values
    private func getCGOrientationFromUIImage(_ image: UIImage) -> CGImagePropertyOrientation {
        
            switch image.imageOrientation {
            case .down:
                return .down
            case .left:
                return .left
            case .right:
                return .right
            case .up:
                return .up
            case .downMirrored:
                return .downMirrored
            case .leftMirrored:
                return .leftMirrored
            case .rightMirrored:
                return .rightMirrored
            case .upMirrored:
                return .upMirrored
            }
    }
    
    // get results and call draw detections method
    private func processDetections(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to detect anything.\n\(error!.localizedDescription)")
                return
            }
        
            let detections = results as! [VNRecognizedObjectObservation]
            self.drawDetectionsOnPreview(detections: detections)
            
            let board = self.solver.getCardsFromDetections(detections: detections)
            //print(self.solver.solve(board))
            let sets = self.solver.solve(board)
            print(sets)
            print("------------\n************\n------------")
            if sets.count == 0 {
                self.navigationItem.title = "No Sets!"
            } else {
                self.navigationItem.title = "There is at least one Set!"
            }
        }
    }
       
    func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]) {
        guard let image = self.photoImageView?.image else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        image.draw(at: CGPoint.zero)
        
        print(detections.count)
        
        for detection in detections {
            let info = detection.labels.first!.identifier + String(format: " %.02f", detection.labels.first!.confidence)
            print(info)
            print("------------")
            
//            The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
            let boundingBox = detection.boundingBox
            let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
            
            // Theoretically able to force unwrap, since image context begins before this loop
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.green.cgColor)
            context.setLineWidth(10)
            context.addRect(rectangle)
            context.drawPath(using: .stroke)
            
            let textColor = UIColor.green
            let textFont = UIFont(name: "Helvetica Bold", size: image.size.width / 25)!

            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]
//            image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
//
            info.draw(in: rectangle, withAttributes: textFontAttributes)
            
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.photoImageView?.image = newImage
    }
    
}

//MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        self.photoImageView?.image = image
        updateDetections(for: image)
    }
}
