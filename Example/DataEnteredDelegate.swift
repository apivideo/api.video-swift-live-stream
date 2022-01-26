//
//  DataEnteredDelegate.swift
//  Example
//
//  Created by Romain Petit on 19/01/2022.
//

import Foundation

protocol DataEnteredDelegate: AnyObject {
    func sendDataBack(endpoint: String, streamkey:String)
}
