//
//  ViewController.swift
//  whaFlower
//
//  Created by mohamed hashem on 11/7/18.
//  Copyright © 2018 mohamed hashem. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController , UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    var pickedImage : UIImage?
    let imagePiker = UIImagePickerController()
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var InfoAboutPhoto: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePiker.delegate = self
        InfoAboutPhoto.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        
        
    }
    
    
    //MARK: - Delegate function finish take photo whate do
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let imageInfo = info[UIImagePickerController.InfoKey.editedImage] as? UIImage  {
            
            guard let convertedCIImage = CIImage(image: imageInfo) else {
                fatalError("Code not Convert to CIImage")
            }
            
            pickedImage = imageInfo
            
            detect(flowerImage: convertedCIImage)
            
        }
        
        
        imagePiker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - recognize classification of  photo
    func detect(flowerImage: CIImage)  {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("cannot import model")
        }
        
        
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard  let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("not correct result of classification")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.InfoAboutPhoto.backgroundColor = #colorLiteral(red: 0.1058823529, green: 0.6392156863, blue: 0.8980392157, alpha: 1)
            self.sendApiTowiki(flowerName: classification.identifier)
            
        }
        
        
        
        let handeler = VNImageRequestHandler(ciImage: flowerImage)
        do {
            try handeler.perform([request])
        }catch{
            print("cannot handle \(error)")
        }
        
    }
    
    
    //MARK: - recognize classification of  photo
    func sendApiTowiki(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                let flowerJson: JSON = JSON(response.result.value!)
                let numberPage = flowerJson["query"]["pageids"][0].stringValue
                let TextData   = flowerJson["query"]["pages"][numberPage]["extract"].stringValue
                
                self.InfoAboutPhoto.text = TextData
                let flowerImageURL = flowerJson["query"]["pages"][numberPage]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
            }
        }
    }
    
    //MARK: - button function to run take camira
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        
        imagePiker.sourceType = .savedPhotosAlbum
        imagePiker.allowsEditing = true
        present(imagePiker, animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        imageView.image = UIImage(named: "")
        navigationItem.title = ""
        InfoAboutPhoto.text = ""
        InfoAboutPhoto.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        
    }
}

