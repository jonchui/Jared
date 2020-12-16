//
//  Router.swift
//  Jared
//
//  Created by Zeke Snider on 4/20/20.
//  Copyright © 2020 Zeke Snider. All rights reserved.
//

import AppKit
import Foundation
import JaredFramework

class Router : RouterDelegate {
    var pluginManager: PluginManagerDelegate
    var messageDelegates: [MessageDelegate]
    
    init(pluginManager: PluginManagerDelegate, messageDelegates: [MessageDelegate]) {
        self.pluginManager = pluginManager
        self.messageDelegates = messageDelegates
    }
    
    func route(message myMessage: Message) {
        messageDelegates.forEach { delegate in delegate.didProcess(message: myMessage) }
        
        // Currently don't process any images
        guard let messageText = myMessage.body as? TextBody else {
            return
        }
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: messageText.message, options: [], range: NSMakeRange(0, messageText.message.count))
        let myLowercaseMessage = messageText.message.lowercased()
        
        let defaults = UserDefaults.standard
        
        guard !defaults.bool(forKey: JaredConstants.jaredIsDisabled) || myLowercaseMessage == "/enable" else {
            return
        }
        
        RootLoop: for route in pluginManager.getAllRoutes() {
            guard (pluginManager.enabled(routeName: route.name)) else {
                break
            }
            for comparison in route.comparisons {
                if comparison.0 == .containsURL {
                    for match in matches {
                        let url = (messageText.message as NSString).substring(with: match.range)
                        for comparisonString in comparison.1 {
                            if url.contains(comparisonString) {
                                let urlMessage = Message(body: TextBody(url), date: myMessage.date ?? Date(), sender: myMessage.sender, recipient: myMessage.recipient, attachments: [])
                                route.call(urlMessage)
                            }
                        }
                    }
                }
                    
                else if comparison.0 == .startsWith {
                    for comparisonString in comparison.1 {
                        if myLowercaseMessage.hasPrefix(comparisonString.lowercased()) {
                            route.call(myMessage)
                        }
                    }
                }
                    
                else if comparison.0 == .contains {
                    for comparisonString in comparison.1 {
                        if myLowercaseMessage.contains(comparisonString.lowercased()) {
                            route.call(myMessage)
                        }
                    }
                }
                    
                else if comparison.0 == .is {
                    for comparisonString in comparison.1 {
                        if myLowercaseMessage == comparisonString.lowercased() {
                            route.call(myMessage)
                        }
                    }
                }
                else if comparison.0 == .isReaction {
                    if myMessage.action != nil {
                        route.call(myMessage)
                    }
                }
                else if comparison.0 == .isMFA {
                    if let MFA = myLowercaseMessage.optional4or6DigitMFA() {
                        
                        // Set string to clipboard
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                        pasteboard.setString(MFA, forType: NSPasteboard.PasteboardType.string)
                        NSSound.purr?.play()
                        print("GOT MFA: \(MFA) ... Copying to clipboard")
                    }
                }
            }
        }
    }
}

extension String {
    func optional4or6DigitMFA() -> String?{
        let regex = try! NSRegularExpression(pattern: "(\\d{2,3}\\-?\\d{2,3})")
        let range = NSRange(location: 0, length: self.utf16.count)
        if let match = regex.matches(in: self, options: [], range: range).last {
            return (self as NSString).substring(with: match.range)
        }
        return nil
    }
}


import AppKit



public extension NSSound {
    static let basso     = NSSound(named: .basso)
    static let blow      = NSSound(named: .blow)
    static let bottle    = NSSound(named: .bottle)
    static let frog      = NSSound(named: .frog)
    static let funk      = NSSound(named: .funk)
    static let glass     = NSSound(named: .glass)
    static let hero      = NSSound(named: .hero)
    static let morse     = NSSound(named: .morse)
    static let ping      = NSSound(named: .ping)
    static let pop       = NSSound(named: .pop)
    static let purr      = NSSound(named: .purr)
    static let sosumi    = NSSound(named: .sosumi)
    static let submarine = NSSound(named: .submarine)
    static let tink      = NSSound(named: .tink)
}



public extension NSSound.Name {
    static let basso     = NSSound.Name("Basso")
    static let blow      = NSSound.Name("Blow")
    static let bottle    = NSSound.Name("Bottle")
    static let frog      = NSSound.Name("Frog")
    static let funk      = NSSound.Name("Funk")
    static let glass     = NSSound.Name("Glass")
    static let hero      = NSSound.Name("Hero")
    static let morse     = NSSound.Name("Morse")
    static let ping      = NSSound.Name("Ping")
    static let pop       = NSSound.Name("Pop")
    static let purr      = NSSound.Name("Purr")
    static let sosumi    = NSSound.Name("Sosumi")
    static let submarine = NSSound.Name("Submarine")
    static let tink      = NSSound.Name("Tink")
}
