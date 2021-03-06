//
//  ViewController.swift
//  macOS Utilities
//
//  Created by Keaton Burleson on 7/23/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Cocoa
import AppFolder
import CocoaLumberjack

class ApplicationViewController: NSViewController, NSCollectionViewDelegate {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var installMacOSButton: NSButton?
    @IBOutlet weak var copyrightLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!

    private var preferenceLoader: PreferenceLoader? = nil
    private let itemRepository = ItemRepository.shared
    private var peerCommunicationService: PeerCommunicationService? = nil

    private var disabledPaths: [IndexPath] = []
    private let reloadQueue = DispatchQueue(label: "thread-safe-obj", attributes: .concurrent)

    private var applicationsInSections: [[Application]] {
        return itemRepository.allowedApplications.count > 4 ? itemRepository.allowedApplications.chunked(into: 4) : [itemRepository.allowedApplications]
    }

    private var allItems: [NSCollectionAppCell] {
        var items: [NSCollectionAppCell] = []
        self.applicationsInSections.enumerated().forEach {
            let section = $0.offset
            $0.element.enumerated().forEach {
                let index = $0.offset
                if let item = self.collectionView.item(at: IndexPath(item: index, section: section)) as? NSCollectionAppCell {
                    items.append(item)
                }
            }
        }
        return items
    }

    static let reloadApplications = Notification.Name("ReloadApplications")

    override func viewDidLoad() {
        super.viewDidLoad()

        if let appVersion = AppDelegate.getApplicationVersion() {
            self.versionLabel.stringValue = "Version \(appVersion)"
        }


        self.registerForNotifications()
        self.showIPAddress()

        if let collectionViewNib = NSNib(nibNamed: "NSCollectionAppCell", bundle: nil) {
            collectionView.register(collectionViewNib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NSCollectionAppCell"))
        }
    }

    override func viewDidAppear() {
        if self.peerCommunicationService == nil {
            self.peerCommunicationService = PeerCommunicationService.instance
        }

        self.peerCommunicationService?.updateStatus("Idle")
    }

    private func checkForExceptions() {
        if !ExceptionHandler.hasExceptions {
            return
        }

        showInfoAlert(title: "Hello There", message: "Looks like macOS Utilities crashed the last time it was used. Would you like to log this issue?") { (shouldLog) in
            if (shouldLog) {
                ExceptionHandler.exceptions.forEach({ (exceptionItem) in
                    var message = "Exception at \(exceptionItem.exceptionDate): \n"
                    message += "Name: \(exceptionItem.exception.name).\n"
                    message += "\(exceptionItem.exception)"

                    DDLogError(message)
                })

                ExceptionHandler.clearExceptions()
            }
        }
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ApplicationViewController.addApplication(_:)), name: GlobalNotifications.newApplication, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ApplicationViewController.reloadAllApplications), name: GlobalNotifications.newApplications, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ApplicationViewController.reloadAllApplications), name: GlobalNotifications.reloadApplications, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ApplicationViewController.addInstaller(_:)), name: GlobalNotifications.newInstaller, object: nil)
    }

    private func showIPAddress() {
        guard let networkAddress = (NetworkUtils.getAllAddresses().first { (address) -> Bool in
            let validIP = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
            return (address.range(of: validIP, options: .regularExpression) != nil)
        }) else {
            return
        }

        self.copyrightLabel.stringValue = "Copyright 2018 ER2 - IP: \(networkAddress) - Remote Log: \(networkAddress):8080"
    }

    @objc private func addInstaller(_ aNotification: Notification? = nil) {
        guard let notification = aNotification else { return }
        if (notification.object as? Installer) != nil {
            DispatchQueue.main.async {
                self.installMacOSButton?.isEnabled = true

                if #available(OSX 10.12.2, *) {
                    self.addTouchBarInstallButton()
                }
            }
        }
    }

    @objc private func addApplication(_ aNotification: Notification? = nil) {
        guard let notification = aNotification else { return }
        if (notification.object as? Application) != nil {
            self.hideAllApplications()
            self.collectionView.reloadData()
            self.configureCollectionView()
            self.showAllApplications()
        }
    }

    @objc private func reloadAllApplications() {
        self.hideAllApplications()

        DispatchQueue.main.async {
            KBLogDebug("Reloading all applications")


            DispatchQueue.main.async {
                self.configureCollectionView()
            }

            self.collectionView.reloadData()

            DispatchQueue.main.async {
                self.showAllApplications()
            }
        }
    }

    private func hideAllApplications() {
        allItems.forEach { $0.hide() }
    }

    private func showAllApplications() {
        allItems.forEach { $0.show() }
    }

    private func configureCollectionView() {
        if itemRepository.allowedApplications.count > 0 {
            let flowLayout = NSCollectionViewFlowLayout()

            let collectionViewWidth = 640
            let collectionViewHeight = 291.0

            let itemWidth = 100
            let itemHeight = 120

            let totalNumberOfItems = itemRepository.allowedApplications.count
            let numberOfItemsInSections = self.applicationsInSections.map { $0.count }

            let itemSpacing = (collectionViewWidth - (numberOfItemsInSections.first! * itemWidth)) / numberOfItemsInSections.first!

            flowLayout.itemSize = NSSize(width: itemWidth, height: itemHeight)


            if totalNumberOfItems < 3 {
                flowLayout.minimumLineSpacing = 3.0
                flowLayout.sectionInset = NSEdgeInsets(top: CGFloat(collectionViewHeight / 4.0), left: CGFloat(collectionViewWidth / 8), bottom: 10.0, right: CGFloat(collectionViewWidth / 8))
            } else if totalNumberOfItems < 4 {
                flowLayout.minimumLineSpacing = 3.0
                flowLayout.sectionInset = NSEdgeInsets(top: CGFloat(collectionViewHeight / 4.0), left: CGFloat(collectionViewWidth / 12), bottom: 10.0, right: CGFloat(collectionViewWidth / 12))
            } else if totalNumberOfItems == 4 {
                flowLayout.minimumLineSpacing = 0.0
                flowLayout.sectionInset = NSEdgeInsets(top: CGFloat(collectionViewHeight / 4.0), left: 10.0, bottom: 10.0, right: 10.0)
            } else if totalNumberOfItems > 4 {
                flowLayout.minimumLineSpacing = 0.0
                flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            }

            flowLayout.minimumInteritemSpacing = CGFloat(itemSpacing)
            collectionView.collectionViewLayout = flowLayout
        }
    }

    private func updateScrollViewContentSize() {
        if let window = collectionView?.window {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setAnimationDuration(0.0)
            let originalFrame = window.frame
            var frame = originalFrame
            frame.origin.y = frame.origin.y - 0.025
            frame.size.height = frame.size.height + 0.025
            window.setFrame(frame, display: false)
            CATransaction.commit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) {
                window.setFrame(originalFrame, display: false)
            }
        }
    }

    @IBAction func ejectCDTray(_ sender: NSMenuItem) {
        let ejectProcess = Process()
        ejectProcess.launchPath = "/usr/bin/drutil"
        ejectProcess.arguments = ["tray", "eject"]
        ejectProcess.launch()
    }

    @IBAction func installMacOSButtonClicked(_ sender: NSButton) {
        self.startMacOSInstall()
    }

    @objc private func startMacOSInstall() {
        PageController.shared.showPageController()
    }

    @objc private func openPreferences() {
        if let preferencesWindow = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "preferencesWindowController") as? NSWindowController {
            preferencesWindow.showWindow(self)
        }
    }

    @objc private func getInfo() {
        if let getInfoWindow = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "getInfoWindowController") as? NSWindowController {
            getInfoWindow.showWindow(self)
        }
    }

    @available(OSX 10.12.2, *)
    func removeTouchBarInstallButton() {
        if let touchBar = self.touchBar {
            touchBar.defaultItemIdentifiers = [.getInfo, .openPreferences]
        }
    }

    @available(OSX 10.12.2, *)
    func addTouchBarInstallButton() {
        if let touchBar = self.touchBar {
            touchBar.defaultItemIdentifiers = [.installMacOS, .getInfo, .openPreferences]
        }
    }
}

extension ApplicationViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let indexPath = indexPaths.first!

        let applicationsInSection = applicationsInSections[indexPath.section]
        let applicationFromSection = applicationsInSection[indexPath.item]

        if !applicationFromSection.isValid {
            disabledPaths.append(indexPath)
        }

        itemRepository.openApplication(applicationFromSection)
        PeerCommunicationService.instance.updateStatus("Running \(applicationFromSection.name)")
        deselectAllItems(indexPaths)
    }

    func deselectAllItems(_ indexPaths: Set<IndexPath>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.collectionView.deselectItems(at: indexPaths)
        }
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return applicationsInSections.count
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if applicationsInSections.indices.contains(section) {
            return applicationsInSections[section].count
        }
        return itemRepository.allowedApplications.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NSCollectionAppCell"), for: indexPath)
        var applicationsInSection = [Application]()

        if applicationsInSections.indices.contains(indexPath.section) {
            applicationsInSection = applicationsInSections[indexPath.section]
        }

        if applicationsInSection.indices.contains(indexPath.item) {
            let applicationFromSection = applicationsInSection[indexPath.item]

            if !applicationFromSection.isValid {
                disabledPaths.append(indexPath)
            }

            return applicationFromSection.getCollectionViewItem(item: item)
        }
        return item
    }
}

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let installMacOS = NSTouchBarItem.Identifier("com.keaton.utilities.installMacOS")
    static let getInfo = NSTouchBarItem.Identifier("com.keaton.utilities.getInfo")
    static let closeCurrentWindow = NSTouchBarItem.Identifier("com.keaton.utilities.closeCurrentWindow")
    static let backPageController = NSTouchBarItem.Identifier("com.keaton.utilities.back")
    static let nextPageController = NSTouchBarItem.Identifier("com.keaton.utilities.next")
    static let openPreferences = NSTouchBarItem.Identifier("com.keaton.utilities.openPreferences")
}

@available(OSX 10.12.2, *)
extension ApplicationViewController: NSTouchBarDelegate {

    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.getInfo, .openPreferences]

        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {

        case NSTouchBarItem.Identifier.installMacOS:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(image: NSImage(named: "NSInstallIcon")!, target: self, action: #selector(startMacOSInstall))
            return item

        case NSTouchBarItem.Identifier.getInfo:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(image: NSImage(named: "NSTouchBarGetInfoTemplate")!, target: self, action: #selector(getInfo))
            return item

        case NSTouchBarItem.Identifier.openPreferences:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(image: NSImage(named: "NSActionTemplate")!, target: self, action: #selector(openPreferences))
            return item

        default: return nil
        }
    }
}
