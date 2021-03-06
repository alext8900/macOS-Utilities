//
//  ModelYearDetermination.swift
//  macOS Utilities
//
//  Created by Keaton Burleson on 11/20/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import CocoaLumberjack

class ModelYearDetermination {
    let modelIdentifier = Sysctl.model

    private (set) public var installableVersions: [Version] = [Version.elCapitan, Version.highSierra]

    func canInstallMojave() {
        installableVersions.append(Version.mojave)
    }

    func determineInstallableVersions() -> [Version] {
        if modelIdentifier.contains("MacBookPro") {
            // MacBook Pro
            let identifierDigits = getIdentifierDigitsFor("MacBookPro")
            if(identifierDigits > 91) {
                canInstallMojave()
            }
        } else if modelIdentifier.contains("MacBookAir") {
            // MacBook Air
            let identifierDigits = getIdentifierDigitsFor("MacBookAir")
            if(identifierDigits > 51) {
                canInstallMojave()
            }
        } else if modelIdentifier.contains("MacBook") {
            // MacBook
            let identifierDigits = getIdentifierDigitsFor("MacBook")
            if(identifierDigits > 81) {
                canInstallMojave()
            }
        } else if modelIdentifier.contains("Macmini") {
            // Mac Mini
            let identifierDigits = getIdentifierDigitsFor("Macmini")
            if(identifierDigits > 61) {
                canInstallMojave()
            }
        } else if modelIdentifier.contains("MacPro") {
            // Mac Pro
            let identifierDigits = getIdentifierDigitsFor("MacPro")
            installableVersions.append(Version.mavericks)
            if(identifierDigits > 41) {
                canInstallMojave()
            }
        } else if modelIdentifier.contains("iMac") {
            // iMac
            let identifierDigits = getIdentifierDigitsFor("iMac")
            if(identifierDigits > 131) {
                canInstallMojave()
            }
        }
        return installableVersions.reversed()
    }

    func getIdentifierDigitsFor(_ modelName: String) -> Int {
        return Int(modelIdentifier.replacingOccurrences(of: modelName, with: "").replacingOccurrences(of: ",", with: ""))!
    }
}

