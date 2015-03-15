import CloudKit
import MultipeerConnectivity
import PromiseKit


func pair(username: String) -> Promise<Void> {
    let container = CKContainer.defaultContainer()
    let db = container.publicCloudDatabase

    return container.fetchUserRecordID().then { user -> Promise<Void> in
        let pairer = Pairer(recordName: user.recordName, petName: username)
        return pairer.promise.then { (loverRecordID, loverName)  -> Promise<Void> in

            // this to ensure pairer lives as long as this promise
            pairer.browser.stopBrowsingForPeers()

            return db.fetchAllSubscriptions().then { subs -> Promise<[String]> in
                return when(subs.map{ db.deleteSubscriptionWithID($0.subscriptionID) })
            }.then { _ -> Promise<CKSubscription> in
                let predicate = NSPredicate(format: "target == %@", CKReference(recordID: user, action: .DeleteSelf))
                let sub = CKSubscription(recordType: "Kiss", predicate: predicate, options: .FiresOnRecordCreation)
                sub.notificationInfo = CKNotificationInfo()
                sub.notificationInfo.alertBody = "\(loverName) loves you"
                sub.notificationInfo.soundName = "Kiss.caf"
                sub.notificationInfo.shouldBadge = true
                return db.save(sub)
            }.then { _ -> Void in
                App.registerForRemoteNotifications()
                NSUserDefaults.standardUserDefaults().lover = (loverRecordID, loverName)
            }
        }
    }
}

@objc private class Pairer: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser
    let session: MCSession
    let json: [String: String]

    let (promise, fulfill, reject) = Promise<(CKRecordID, String)>.defer()

    init(recordName: String, petName: String) {
        json = ["name": petName, "id": recordName]
        let peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: peer)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "mxcl-luv")
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "mxcl-luv")
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    @objc func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        reject(error)
    }

    @objc func browser(browser: MCNearbyServiceBrowser!, foundPeer: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        browser.invitePeer(foundPeer, toSession: session, withContext: nil, timeout: 0)
    }

    @objc func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {

    }

    @objc func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        reject(error)
    }

    @objc func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        invitationHandler(true, session)
    }

    @objc func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch state {
        case .Connecting:
            println("Connecting")
        case .Connected:
            println("Connected")
            var error: NSError?
            if let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(), error: &error) {
                if !session.sendData(data, toPeers: [peerID], withMode: .Reliable, error: &error) {
                    reject(error!)
                }
            } else {
                reject(error!)
            }
        case .NotConnected:
            println("NotConnected")
        }
    }

    @objc func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        var error: NSError?
        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &error) as? NSDictionary {

            let name = json["name"] as? String
            let recordName = json["id"] as? String

            if name != nil && recordName != nil {
                fulfill((CKRecordID(recordName: recordName), name!))
            } else {
                reject(NSError(luv: "Multipeer communications error"))
            }
        } else {
            reject(error!)
        }
    }

    @objc func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        certificateHandler(true)
    }

    @objc func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        println("didStartReceivingResourceWithName \(resourceName)")
    }

    @objc func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        if error != nil {
            reject(error)
        }
    }

    @objc func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        println("didReceiveStream \(stream)")
    }
}
