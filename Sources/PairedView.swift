import iAd
import PromiseKit
import StoreKit
import UIKit


class PairedView: UIView {
    let heart: UIButton
    let cog = CogButton()
    weak var ad: ADBannerView?
    let status = SwishLabel()

    var loverName: String {
        return heart.currentTitle!
    }

    convenience init(lover: String) {
        self.init(frame: UIScreen.mainScreen().bounds)

        heart.setTitle(lover, forState: .Normal)

        if NSUserDefaults.standardUserDefaults().isFirstKiss {
            after(0.1).then {
                self.status.text = "Tap the heart to send\n\(lover) a kiss!"
            }
        }
    }

    override init(frame: CGRect) {
        heart = HeartButton()
        heart.setBackgroundImage(UIImage(named: "Heart"), forState: .Normal)
        heart.setTitleColor(UIColor.pink2(), forState: .Normal)
        heart.titleLabel!.font = UIFont(name: "SnellRoundhand-Black", size: 40)
        heart.titleLabel!.adjustsFontSizeToFitWidth = true
        heart.titleLabel!.clipsToBounds = false
        heart.titleLabel!.textAlignment = .Center
        heart.sizeToFit()

        super.init(frame: frame)

        addSubview(heart)
        addSubview(cog)
        addSubview(status)

        if !IAP.RemoveAds.purchased {
            let iad = ADBannerView(adType: .Banner)
            ad = iad
            iad.hidden = true
            iad.delegate = self
            addSubview(iad)
        }

        // ideally wouldn't do this if IAP purchased, but don't know
        // if it is safe to removeTransactionObserver if not added
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        heart.center = bounds.center
        cog.center.y = 20 + 5 + cog.bounds.size.height / 2
        cog.center.x = bounds.size.width - cog.bounds.size.width / 2 - 5

        if let iad = ad {
            iad.frame.origin.x = 0
            iad.frame.origin.y = bounds.size.height
            iad.frame.origin.y -= iad.bounds.size.height
        }

        status.frame = CGRectInset(bounds, 20, 20)
        status.frame.size.height = 62

        status.center.x = heart.center.x
        status.center.y = CGRectGetMaxY(heart.frame) + status.bounds.size.height / 2 + 20
    }
}


private class HeartButton: UIButton {
    override func titleRectForContentRect(contentRect: CGRect) -> CGRect {
        return CGRectMake(10, 15, 180, 100)
    }
}


extension PairedView: ADBannerViewDelegate {
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        banner.hidden = true
    }

    func bannerViewDidLoadAd(banner: ADBannerView!) {
        banner.hidden = false
    }
}

extension PairedView: SKPaymentTransactionObserver {
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        func test(pid: String) {
            if pid == IAP.RemoveAds.productIdentifier {
                ad?.removeFromSuperview()
            }
        }

        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchased:
                test(transaction.payment.productIdentifier)
            case .Restored:
                if let transaction = transaction.originalTransaction {
                    test(transaction.payment.productIdentifier)
                }
            default:
                break
            }
        }
    }
}
