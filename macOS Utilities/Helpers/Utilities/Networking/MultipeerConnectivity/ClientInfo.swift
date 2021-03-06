//
//  ClientInfo.swift
//
//
//  Created by Keaton Burleson on 8/28/19.
//

import Foundation
import MultipeerConnectivity

public class ClientInfo: NSObject, NSCoding {
    var serialNumber: String?
    var peerID: MCPeerID?
    var status: String = "Idle"

    init(serialNumber: String, peerID: MCPeerID) {
        self.serialNumber = serialNumber
        self.peerID = peerID
    }

    required public init(coder decoder: NSCoder) {
        self.serialNumber = decoder.decodeObject(forKey: "serialNumber") as? String
        self.peerID = decoder.decodeObject(forKey: "peerID") as? MCPeerID
        self.status = decoder.decodeObject(forKey: "status") as? String ?? "Unknown"
    }

    public func encode(with coder: NSCoder) {
        coder.encode(serialNumber, forKey: "serialNumber")
        coder.encode(peerID, forKey: "peerID")
        coder.encode(status, forKey: "status")
    }
}
