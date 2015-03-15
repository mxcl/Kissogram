import PromiseKit
import StoreKit
import UIKit

protocol MenuViewControllerDelegate {
    func reset()
}


enum MenuItem: Int {
    case Unpair
    case RemoveAds
    case RestorePurchases
    case ShareApp

    static var count: Int { return ShareApp.rawValue + 1 }

    init?(indexPath: NSIndexPath) {
        self.init(rawValue: indexPath.section)
    }

    var text: String {
        switch self {
        case .Unpair:
            return "Reset Phone Pairing"
        case .RemoveAds:
            return IAP.RemoveAds.purchased ? "Ads Removed ✓" : "Remove Ads"
        case .RestorePurchases:
            return "Restore Purchases"
        case .ShareApp:
            return "Share App…"
        }
    }

    var footerText: String? {
        switch self {
        case .Unpair:
            return "Like a reset to factory settings option, but just for this app."
        case .RemoveAds:
            return IAP.RemoveAds.purchased
                ? "Thank you for your purchase!"
                : "Remove ads and help support Kissogram’s developer."
        case .RestorePurchases:
            return nil
        case .ShareApp:
            return "Your friends need love too."
        }
    }

    var indexPath: NSIndexPath {
        return NSIndexPath(forRow: 0, inSection: rawValue)
    }
}

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKPaymentTransactionObserver {
    private let tableView = UITableView(frame: CGRectZero, style: .Grouped)
    private let shadow = UIView()
    private let close = UIButton()

    var delegate: MenuViewControllerDelegate?

    override func viewDidLoad() {
        view.backgroundColor = UIColor.clearColor()
        tableView.backgroundColor = UIColor.hotPink()
        tableView.dataSource = self
        tableView.delegate = self
        shadow.backgroundColor = UIColor(white: 0, alpha: 0.78)

        close.setTitle("CLOSE", forState: .Normal)
        close.setTitleColor(UIColor.pink2(), forState: .Normal)
        close.setTitleColor(UIColor.pink1(), forState: .Highlighted)
        close.titleLabel!.font = UIFont(name: "HelveticaNeue-UltraLight", size: 40)
        close.titleLabel!.adjustsFontSizeToFitWidth = true
        close.sizeToFit()
        close.addTarget(self, action: "dismiss", forControlEvents: .TouchUpInside)

        view.addSubview(shadow)
        view.addSubview(tableView)
        view.addSubview(close)

        let gr = UITapGestureRecognizer(target: self, action: "dismiss")
        shadow.addGestureRecognizer(gr)

        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return MenuItem.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell(menuItem: MenuItem(indexPath: indexPath)!)
    }

    class func present(# inView: UIView) -> Promise<MenuViewController> {
        let vc = MenuViewController()
        vc.modalPresentationStyle = .OverFullScreen

        inView.addSubview(vc.view)
        vc.view.frame = inView.bounds
        vc.viewDidLayoutSubviews()
        let w = vc.tableView.bounds.size.width
        vc.tableView.transform = CGAffineTransformMakeTranslation(w, 0)
        vc.close.transform = vc.tableView.transform
        vc.shadow.alpha = 0

        return UIView.animate(duration: 0.35, animations: {
            vc.shadow.alpha = 1
            vc.tableView.transform = CGAffineTransformIdentity
            vc.close.transform = CGAffineTransformIdentity
        }).then{ _ in vc }
    }

    @objc func dismiss() {
        let w = self.tableView.bounds.size.width

        UIView.animateWithDuration(0.35, animations: {
            self.shadow.alpha = 0
            self.tableView.center.x += w
            self.close.center.x += w
        }, completion: { _ in
            self.dismissViewControllerAnimated(false, completion: nil)
        })
    }

    override func viewDidLayoutSubviews() {
        let h = view.bounds.size.height
        let w = view.bounds.size.width

        tableView.frame = UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsetsMake(0, w / 3, 0, 0))
        shadow.frame = view.bounds
        close.frame.origin.y = h - close.bounds.size.height
        close.center.x = w * 2 / 3
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor(white: 1, alpha: 0.1)
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let txt = MenuItem(rawValue: section)!.footerText {
            let label = UILabel.ultraLight()
            label.font = kFont
            label.text = txt
            label.numberOfLines = 0
            label.textColor = UIColor(white: 1, alpha: 0.613)
            label.shadowColor = nil
            return wrap(label, footerMargin)
        } else {
            return nil
        }
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let menuItem = MenuItem(rawValue: section)!

        if let str = menuItem.footerText {
            let sz = CGRectInset(tableView.bounds, footerMargin, 0).size
            var attrs: [NSObject: AnyObject]! = [:]  // couldn't figure out any other way
            attrs[NSFontAttributeName] = kFont       // to make this shit compile ffs
            let foo = str.boundingRectWithSize(sz, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attrs, context: nil)
            return foo.size.height + footerMargin * 1.25
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch MenuItem(indexPath: indexPath)! {
        case .Unpair:
            let sheet = UIActionSheet()
            sheet.title = "Are You Sure?"
            sheet.destructiveButtonIndex = sheet.addButtonWithTitle("Reset")
            sheet.cancelButtonIndex = sheet.addButtonWithTitle("Cancel")
            sheet.promiseInView(view).then { index -> Void in
                if index != sheet.cancelButtonIndex {
                    NSUserDefaults.standardUserDefaults().lover = nil
                    self.delegate?.reset()
                    self.dismiss()
                }
            }.finally {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        case .RemoveAds:
            let pids: Set<NSObject> = ["RemoveAds"]
            let promise: Promise<SKProductsResponse> = SKProductsRequest(productIdentifiers: pids).promise()
            let _:() = promise.then { response -> Void in
                if let product = response.products.first as? SKProduct {
                    let payment = SKPayment(product: product)
                    SKPaymentQueue.defaultQueue().addPayment(payment)
                }
            }.catch { error in
                UIAlertView.show(error)
            }
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
            spinner.color = UIColor.hotPink()
            spinner.startAnimating()
            tableView.cellForRowAtIndexPath(MenuItem.RemoveAds.indexPath)!.accessoryView = spinner

        case .RestorePurchases:
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()

        case .ShareApp:
            let vc = UIActivityViewController(messagePrefix: "Check out Kissogram!")
            vc.completionWithItemsHandler = { _ in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }

    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        func test(payment: SKPayment) {
            if payment.productIdentifier == IAP.RemoveAds.productIdentifier {
                let ip = MenuItem.RemoveAds.indexPath
                tableView.deselectRowAtIndexPath(ip, animated: true)
                tableView.cellForRowAtIndexPath(ip)!.accessoryView = nil
            }
        }
        for transaction in transactions as! [SKPaymentTransaction] {
            switch transaction.transactionState {

            case .Purchased, .Failed:
                test(transaction.payment)
            case .Restored:
                test(transaction.originalTransaction.payment)
            default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
        tableView.deselectRowAtIndexPath(MenuItem.RestorePurchases.indexPath, animated: true)
    }

    private let kFont = UIFont(name: "HelveticaNeue-Light", size: 12)
    private let footerMargin = CGFloat(10)
}

extension UITableViewCell {
    convenience init(menuItem: MenuItem) {
        self.init(style: .Default, reuseIdentifier: nil)
        textLabel!.text = menuItem.text
        textLabel!.textColor = UIColor.whiteColor()
        textLabel!.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        textLabel!.textAlignment = .Center

        if menuItem == .RemoveAds {
            let label = UILabel()
            label.text = IAP.RemoveAds.price
            label.font = UIFont(name: "HelveticaNeue-Thin", size: 10)
            label.textColor = UIColor(white: 1, alpha: 0.75)
            label.sizeToFit()
            accessoryView = label
        }

        textLabel!.highlightedTextColor = UIColor.hotPink()
        selectedBackgroundView = { let v = UIView(); v.backgroundColor = UIColor.whiteColor(); return v }()
    }
}
