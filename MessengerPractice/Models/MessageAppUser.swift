//
//  MessageAppUser.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/11/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import Foundation

struct MessageAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
   // let profilePictureURL: String
    
    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        //owenbarrott-gmail-com_profile_picture.png
        return"\(safeEmail)_profile_picture.png"
    }
}
