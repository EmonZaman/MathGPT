//
//  HoomePage.swift
//  MathGPT
//
//  Created by Aagontuk on 7/4/25.
//

import UIKit

class HomePage: UIViewController {
    
    @IBOutlet weak var btnScan: UIButton!{
        didSet{
            
            btnScan.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
            
        }
    }
    
    @IBOutlet weak var btnAddImage: UIButton!{
        didSet{
            btnAddImage.addTarget(self, action:  #selector(btnAddImageTapped), for: .touchUpInside)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Here home page calling")
        
        func getImageName(){
            
            var imageName: String?
            
            imageName = "image"
            
            print("Image name is \(imageName ?? "No image name")")
            
        }
        
        

        // Do any additional setup after loading the view.
    }
    
  

    @objc func scanButtonTapped() {
        // Your action code here
        print("Scan button was tapped")
        
        
    }
    
    @objc func btnAddImageTapped() {
        // Your action code here
        print("Image add button was tapped")
        
        
    }
    


}
