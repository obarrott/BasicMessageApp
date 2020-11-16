//
//  ViewController.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/10/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import UIKit
import FirebaseAuth
class ConversationsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    // Checks if User is logged in. If not, it will present the login view controller.
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            // Makes the vc a fullscreen instead of a pop-over
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}


