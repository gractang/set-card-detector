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
    
    @IBOutlet weak var setCollectionView: UICollectionView!
    
    let imagePicker = UIImagePickerController()
    var solver = SetSolver()
    var currSets: [[SetCard]] = []
    var originalImage: UIImage? = nil
      
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
        openCamera()
    }
    
    @IBAction func photoLibraryTapped(_ sender: UIBarButtonItem) {
        openGallery()
    }
    
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Choose Image", message: K.Info.tutorial, preferredStyle: .alert)
      
//        let image = UIImage(named: "Set_Example")
//
//        alert.view.addSubview(imageView)
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("cool")
        })
        
        alert.addAction(ok)
        
        
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
//        imagePicker.sourceType = .photoLibrary
        
        setCollectionView.delegate = self
        setCollectionView.dataSource = self
        
        setCollectionView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellWithReuseIdentifier: K.cellIdentifier)
        
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
//            print(sets)
//            print("------------\n************\n------------")
            if sets.count == 0 {
                self.navigationItem.title = "No Sets!"
            } else {
                self.navigationItem.title = "There is at least one Set!"
            }
            self.currSets = sets
            self.setCollectionView.reloadData()
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
    
    // Draws a given SET onto the image
    func drawSetOnPreview(for set: [SetCard]) {
        
        // check to make sure the original image exists
        // (i think it always will, but just to be safe)
        guard let image = self.originalImage else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        image.draw(at: CGPoint.zero)
        
        for card in set {
            let boundingBox = card.boundingBox
            let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
            
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(30)
            context.addRect(rectangle)
            context.drawPath(using: .stroke)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.photoImageView?.image = newImage
    }
    
    // Set the shouldAutorotate to False
    override open var shouldAutorotate: Bool {
       return false
    }

    // Specify the orientation.
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
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
        self.originalImage = image
        updateDetections(for: image)
    }
    
    // brings up an alert menu and allows the user to pick between camera and gallery
    func cameraOrGallery() {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                imagePicker.sourceType = UIImagePickerController.SourceType.camera
                self.present(imagePicker, animated: true, completion: nil)
            }
            else
            {
                let alert  = UIAlertController(title: "Notice", message: "We don't have access to your camera.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }
            else
            {
                let alert  = UIAlertController(title: "Notice", message: "We don't have access to your gallery.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK: - UICollectionViewDelegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currSets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Queue the cell
        let cell = setCollectionView.dequeueReusableCell(withReuseIdentifier: "setCell", for: indexPath) as! SetCell
        
        // Give the cell rounded corners
        cell.layer.cornerRadius = cell.frame.height / 5
        
        let currentSetIndex = indexPath.row
        cell.cardOne = currSets[currentSetIndex][0]
        cell.cardTwo = currSets[currentSetIndex][1]
        cell.cardThree = currSets[currentSetIndex][2]
        
//        cell.cardOneDesc.text = cell.cardOne?.description
//        cell.cardTwoDesc.text = cell.cardTwo?.description
//        cell.cardThreeDesc.text = cell.cardThree?.description
        
        cell.cardOneImg.image = UIImage(named: currSets[currentSetIndex][0].description)
        cell.cardTwoImg.image = UIImage(named: currSets[currentSetIndex][1].description)
        cell.cardThreeImg.image = UIImage(named: currSets[currentSetIndex][2].description)
        cell.cards = [cell.cardOne!, cell.cardTwo!, cell.cardThree!]
        return cell
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let height = collectionView.frame.size.height
        // let width = collectionView.frame.size.width
//        return CGSize(width: 150.0, height: 100)
        return CGSize(width: 200, height: height * 0.8)
    }
    
    // Triggers upon selection of item
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? SetCell
        //Briefly fade the cell on selection
        UIView.animate(withDuration: 0.25,
                       animations: {
                        //Fade-out
                        cell?.alpha = 0.5
        }) { (completed) in
            UIView.animate(withDuration: 0.25,
                           animations: {
                            //Fade-out
                            cell?.alpha = 1
            })
        }
//        print("Selected cell: \(indexPath.row)")
        drawSetOnPreview(for: (cell?.cards)!)
    }
}
