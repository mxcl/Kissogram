import AVFoundation.AVAudioPlayer
import CloudKit
import PromiseKit
import StoreKit
import UIKit

private enum State {
    case Setup
    case Paired(CKRecordID, String)
    case Error(ErrorType)
}


@UIApplicationMain class App: UIViewController, UIApplicationDelegate {

    var window: UIWindow?
    var contentView: UIView!

    private var state: State! {
        willSet {
            contentView?.removeFromSuperview()
        }
        didSet {
            contentView = {
                switch self.state! {
                case .Setup:
                    let view = SetupView()
                    view.promise.then {
                        self.state = .Paired($0)
                    }.report { error in
                        // this catch is necessary because the unhandled error
                        // handler will not trigger if the promise doesn’t dealloc
                        self.state = .Error(error)
                    }
                    return view

                case .Paired(_, let name):
                    let view = PairedView(lover: name)
                    view.heart.addTarget(self, action: "sendKiss", forControlEvents: .TouchUpInside)
                    view.cog.addTarget(self, action: "showConfig", forControlEvents: .TouchUpInside)
                    return view

                case .Error(let error):
                    let view = ErrorView(error: error)
                    view.retry.addTarget(self, action: "reset", forControlEvents: .TouchUpInside)
                    return view
                }
            }()
            view.addSubview(contentView)
        }
    }

    lazy var player: AVAudioPlayer = {

        class Player: AVAudioPlayer, AVAudioPlayerDelegate {
            @objc func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
                // always be prepared to play
                prepareToPlay()
            }
        }

        let path = NSBundle.mainBundle().pathForResource("Kiss", ofType: "caf")!
        let url = NSURL(fileURLWithPath: path)
        let player = try! Player(contentsOfURL: url)
        player.prepareToPlay()
        player.delegate = player
        return player
    }()

    weak var alert: SCLAlertView?
}


//MARK actions

extension App: MenuViewControllerDelegate {
    func reset() {
        if let lover = NSUserDefaults.standardUserDefaults().lover {
            state = .Paired(lover)
        } else {
            state = .Setup
        }
    }

    func showKiss(name: String) {
        guard alert == nil else { return }

        alert = SCLAlertView()
        alert!.showTitle("\(name) loves you.", completeText: "Yeah, I Know.")
        player.play()
    }

    func sendKiss() {
        guard !player.playing else { return }
        guard case let .Paired(lover, name) = state! else { return }

        let swish = (contentView as! PairedView).status

        swish.text = "Sending Kiss…"

        let kiss = CKRecord(recordType: "Kiss")
        kiss.setObject(CKReference(recordID: lover, action: .DeleteSelf), forKey: "target")

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        CKContainer.defaultContainer().publicCloudDatabase.save(kiss).then { _ -> Void in
            swish.text = "You sent \(name) a kiss!"
            swish.clearAfter(5)
        }.ensure {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }.report { error in
            self.state = .Error(error)
        }

        NSUserDefaults.standardUserDefaults().isFirstKiss = false

        player.play()
    }

    func showConfig() {
        MenuViewController.present(inView: view).then { vc -> Void in
            vc.delegate = self
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
}


//MARK UIApplicationDelegate

extension App {
    func application(app: UIApplication, didFinishLaunchingWithOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.rootViewController = self
        window!.tintColor = UIColor.hotPink()
        window!.makeKeyAndVisible()

        if NSUserDefaults.standardUserDefaults().lover != nil {
            // we have asked the user for push notifications at least once
            // Apple documents that we must continue to ask every app startup
            // because the token *may* change.
            App.registerForRemoteNotifications()
        }

        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

        // prevent app from stopping music
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)

        IAP.RemoveAds.fetchPrice()
        
        return true
    }

    func applicationWillTerminate(application: UIApplication) {
         SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        state = State.Error(error)
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {

        let permissionDenied = !notificationSettings.types.contains(.Alert)

        if permissionDenied {
            state = State.Error(Kissogram.Error.PushNotificationsDisabled)
            //TODO: application.openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        let op = CKModifyBadgeOperation(badgeValue: 0)
        op.modifyBadgeCompletionBlock = { error in
            if error == nil {
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            }
        }
        CKContainer.defaultContainer().addOperation(op)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        defer { completionHandler(.NoData) }

        guard application.applicationState == .Active else { return }
        let note = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
        guard note.notificationType == .Query else { return }
        guard case let .Paired(_, name) = state! else { return }

        showKiss(name)
    }

    func application(application: UIApplication, didReceiveRemoteNotification payload: [NSObject : AnyObject]) {
        guard application.applicationState == .Active else { return }
        guard case let .Paired(_, name) = state! else { return }

        showKiss(name)
    }

    class func registerForRemoteNotifications() {
        let types = UIUserNotificationType(rawValue: UIUserNotificationType.Badge.rawValue | UIUserNotificationType.Alert.rawValue | UIUserNotificationType.Sound.rawValue)
        let settings = UIUserNotificationSettings(forTypes: types, categories:nil)
        let application = UIApplication.sharedApplication()
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
}


//MARK UIViewController

extension App {
    override func loadView() {
        view = GradientBackgroundView()
    }

    override func viewDidLoad() {
        reset()
    }

    override func viewDidLayoutSubviews() {
        contentView?.bounds = view.bounds
        contentView?.center = view.bounds.center
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}


//MARK StoreKit

extension App: SKPaymentTransactionObserver {

    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let app = UIApplication.sharedApplication()

        for transaction in transactions {
            func purchased(pid: String) {
                defaults.setBool(true, forKey: pid)
                queue.finishTransaction(transaction)
                app.networkActivityIndicatorVisible = false
            }

            switch transaction.transactionState {
            case .Purchased:
                purchased(transaction.payment.productIdentifier)
            case .Restored:
                guard let transaction = transaction.originalTransaction else { return print("No original transaction") }
                purchased(transaction.payment.productIdentifier)
            case .Failed:
                paymentQueue(queue, restoreCompletedTransactionsFailedWithError: transaction.error!)
                queue.finishTransaction(transaction)
            case .Purchasing:
                app.networkActivityIndicatorVisible = true
            case .Deferred:
                let alert = UIAlertView()
                alert.title = "Thank You"
                alert.message = "Your purchase is pending approval from your family delegate."
                alert.addButtonWithTitle("OK")
                alert.show()
                app.networkActivityIndicatorVisible = false
            }
        }
    }

    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        if error.code != SKErrorPaymentCancelled {
            UIAlertView.show(error)
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
