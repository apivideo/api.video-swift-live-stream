//
//  UpdateParamDelegate.swift
//  Example
//

import Foundation

protocol UpdateParamDelegate {
    func updateParamResolution(variable: String)
    func updateParamFramerate(variable: String)
    func updateParamAudioBitrate(variable: String)
    func updateParamEndpoint(variable: String)
    func updateParamStreamKey(variable: String)
    func updateParamVideoBitrate(variable: Int)
}
