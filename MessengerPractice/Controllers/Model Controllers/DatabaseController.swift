//
//  DatabaseController.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/11/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseController {
    
    // MARK: - Properties
    static let shared = DatabaseController()
    
    private let database = Database.database().reference()
    
    // MARK: - CRUD Functions
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else {
                return completion(false) }
        }
        completion(true)
    }
    
    /// Inserts new user to database
    public func insertUser(with user: MessageAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name" : user.lastName
        ])
    }
}
