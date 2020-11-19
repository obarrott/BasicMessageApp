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
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    // MARK: - CRUD Functions
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseController.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Inserts new user to database
    public func insertUser(with user: MessageAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name" : user.lastName
            ], withCompletionBlock: { error, _ in
                guard error == nil else {
                    print("Failed to write to the database.")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        //append to user dictionary
                        let newElement = [
                            "name" : user.firstName + " " + user.lastName,
                            "email" : user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    } else {
                        // create that array if it doesn't exist
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                }
        })
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String : String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String : String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
}

// MARK: - Extensions

// MARK: - Sending messages / conversations
extension DatabaseController {
    
    /// Creates a new conversation with the target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseController.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
            ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false)
                    print("user not found")
                    return
                }
                
                let messageDate = firstMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)
                
                var message = ""
                
                switch firstMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .linkPreview(_):
                    break
                case .custom(_):
                    break
                }
                
                let conversationID = "conversation_\(firstMessage.messageId)"
                
                let newConversationData: [String: Any] = [
                    "id" : conversationID,
                    "other_user_email": otherUserEmail,
                    "name": name,
                    "latest_message" : [
                        "date": dateString,
                        "message" : message,
                        "is_read" : false
                    ]
                ]
                
                let recipient_newConversationData: [String: Any] = [
                    "id" : conversationID,
                    "other_user_email": safeEmail,
                    "name": "Self",
                    "latest_message" : [
                        "date": dateString,
                        "message" : message,
                        "is_read" : false
                    ]
                ]
                
                // Update recipient conversation entry
                self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                    if var conversations = snapshot.value as? [[String : Any]] {
                        //append
                        conversations.append(recipient_newConversationData)
                        self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)
                    } else {
                        // create
                        self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                    }
                }
                
                // Update current user conversation entry
                if var conversations = userNode["conversations"] as? [[String : Any]] {
                    //conversation array exists for current user
                    // you should append
                    conversations.append(newConversationData)
                    userNode["conversations"] = conversations
                    ref.setValue(userNode, withCompletionBlock:  { [weak self] (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    })
                } else {
                    // conversation array does not exist
                    // create it
                    userNode["conversations"] = [
                        newConversationData
                    ]
                    
                    ref.setValue(userNode) { [weak self] (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                        
                }
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        "id": String,
//        "type": text, photo, video,
//        "content": String,
//        "date": Date(),
//        "sender_email": String,
//        "isRead": true/false,
//
  
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
            
        }
        
        let currentUserEmail = DatabaseController.safeEmail(emailAddress: userEmail)
        
        let collectionMessage: [String : Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
            collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { (dictionary) in
                guard let conversationID = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String : Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        return nil
                        
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                
            }
            completion(.success(conversations))
        }
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { (dictionary) in
                guard let content = dictionary["content"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let messageID = dictionary["id"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let name = dictionary["name"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                    
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                    return Message(sender: sender,
                                   messageId: messageID,
                                   sentDate: date,
                                   kind: .text(content))
                }
            completion(.success(messages))
        }
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping(Bool) -> Void) {
        
    }
}
