//
//  Message.swift
//  MessengerPractice
//
//  Created by Owen Barrott on 11/16/20.
//  Copyright © 2020 Owen Barrott. All rights reserved.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    
}
