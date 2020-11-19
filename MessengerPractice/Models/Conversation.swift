//
//  Conversation.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/18/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
