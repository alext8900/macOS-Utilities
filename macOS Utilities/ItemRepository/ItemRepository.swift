//
//  ItemRepository.swift
//  macOS Utilities
//
//  Created by Keaton Burleson on 4/4/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import CocoaLumberjack

class ItemRepository {
    public static let shared = ItemRepository()
    private (set) public var items: [Any] = []

    static let newApplication = Notification.Name("NSNewApplication")
    static let newDisk = Notification.Name("NSNewDisk")
    static let newInstaller = Notification.Name("NSNewInstaller")
    static let newVolume = Notification.Name("NSNewVolume")

    private init() {
        DDLogInfo("ItemRepository initialized")
        DispatchQueue.main.async {
            DiskUtility.shared.getAllDisks()
            ApplicationUtility.shared.getApplications()
            ApplicationUtility.shared.getUtilities()
        }

    }

    public func getDisks() -> [Disk] {
        return (items.filter { type(of: $0) == Disk.self } as! [Disk]).sorted { $0.deviceIdentifier < $1.deviceIdentifier }
    }

    public func getVolumes() -> [Volume] {
        return (items.filter { type(of: $0) == Volume.self } as! [Volume]).sorted { $0.volumeName < $1.volumeName }
    }

    public func getInstallers() -> [Installer] {
        return (items.filter { type(of: $0) == Installer.self } as! [Installer]).sorted { $0.versionNumber < $1.versionNumber }
    }

    public func getApplications() -> [Application] {
        return (items.filter { type(of: $0) == Application.self } as! [Application]).sorted { $0.name < $1.name }
    }

    public func addToRepository(newDisk: Disk) {
        if(self.items.contains { ( $0 as? Disk) != nil && ( $0 as! Disk).id == newDisk.id } == false) {
            DDLogInfo("Adding disk \(newDisk.id) to repo")
            self.items.append(newDisk)
            NotificationCenter.default.post(name: ItemRepository.newDisk, object: nil)
        }
    }

    public func addToRepository(newVolume: Volume) {
        if(self.items.contains { ( $0 as? Volume) != nil && ( $0 as! Volume).id == newVolume.id } == false) {
            DDLogInfo("Adding volume \(newVolume.id) to repo")
            self.items.append(newVolume)
            NotificationCenter.default.post(name: ItemRepository.newVolume, object: nil)
        }
    }

    public func addToRepository(newInstaller: Installer) {
        if (self.items.contains { ( $0 as? Installer) != nil && ( $0 as! Installer).id == newInstaller.id } == false) {
            DDLogInfo("Adding installer \(newInstaller.id) to repo")
            self.items.append(newInstaller)
            NotificationCenter.default.post(name: ItemRepository.newInstaller, object: nil)
        }
    }

    public func addToRepository(newApplication: Application) {
        if (self.items.contains { ( $0 as? Application) != nil && ( $0 as! Application).id == newApplication.id } == false) {
            if(newApplication.isUtility == false) {
                DDLogInfo("Adding application \(newApplication.id) to repo")
                DDLogInfo(newApplication.description)
            } else {
                DDLogInfo("Adding utility \(newApplication.id) to repo")
            }
            
            self.items.append(newApplication)
            NotificationCenter.default.post(name: ItemRepository.newApplication, object: nil)
        }
    }


}