//
//  ViewController.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/10/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        
        // Checks if User is logged in. If not, it will present the login view controller.
        if !isLoggedIn {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            // Makes the vc a fullscreen instead of a pop-over
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }


}


