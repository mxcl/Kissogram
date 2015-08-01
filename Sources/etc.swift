enum Error: ErrorType {
    case PushNotificationsDisabled
    case UnknownPairingError
    case MultipeerCommunicationsError
}


////////////////////////////////////////////////////////////// Foundation
import Foundation
import CloudKit.CKRecordID

private let RecordKey = "LoverRecordName"
private let NameKey = "LoverName"
private let SentFirstKissKey = "SentFirstKissKey"

extension NSUserDefaults {
    var lover: (CKRecordID, String)? {
        get {
            if let recordName = objectForKey(RecordKey) as? String {
                if let name = objectForKey(NameKey) as? String {
                    return (CKRecordID(recordName: recordName), name)
                }
            }
            return nil
        }

        set {
            let recordName = newValue?.0.recordName
            let personName = newValue?.1
            if recordName != nil && personName != nil {
                setObject(recordName, forKey: RecordKey)
                setObject(personName, forKey: NameKey)
            } else {
                removeObjectForKey(NameKey)
                removeObjectForKey(RecordKey)
            }
        }
    }

    var isFirstKiss: Bool {
        get {
            return !boolForKey(SentFirstKissKey)
        }
        set {
            setBool(!newValue, forKey: SentFirstKissKey)
        }
    }
}


extension NSCoder {
    class func empty() -> NSCoder {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.finishEncoding()
        return NSKeyedUnarchiver(forReadingWithData: data)
    }
}


/////////////////////////////////////////////////////////////////// UIKit
import UIKit

extension UIColor {
    convenience init(hex: Int) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    class func hotPink(alpha alpha: CGFloat = 1) -> UIColor {
        return UIColor(hue:0.93, saturation:1, brightness:1, alpha:alpha)
    }

    class func pink1() -> UIColor {
        return UIColor(hex: 0xBB377D)
    }

    class func pink2() -> UIColor {
        return UIColor(hex: 0xFBD3E9)
    }
}

extension UIActivityViewController {
    convenience init(messagePrefix: String) {
        let urlString = "http://appstore.com/kissogram"
        let messageText = "\(messagePrefix) \(urlString)"
        let activityItems: [AnyObject] = [messageText]

        // just makes mail + messages repeat the URL twice FFS
        //        if let url = NSURL(string: urlString) {
        //            activityItems.append(url)
        //        }

        self.init(activityItems: activityItems, applicationActivities:nil)
        setValue("Check out Kissogram!", forKey: "subject")
        excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList]
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.nextResponder()
            if let vc = parentResponder as? UIViewController {
                return vc
            }
        }
        return nil
    }
}

extension UIDevice {
    enum Model {
        case iPhone4
        case iPhone5
        case iPhone6
        case iPhone6Plus
        case Unknown  // iPhone 7 etc.
    }

    class func model() -> Model {
        let sz = UIScreen.mainScreen().bounds.size
        switch (sz.width, sz.height) {
        case (320, 480): return .iPhone4
        case (320, 568): return .iPhone5
        case (375, 667): return .iPhone6
        case (414, 736): return .iPhone6Plus
        default:
            return .Unknown
        }
    }
}

extension UIAlertView {
    class func show(error: ErrorType) {
        let alert = UIAlertView()
        alert.title = "Error"
        alert.message = {
            if let error = error as? Kissogram.Error {
                switch error {
                case .PushNotificationsDisabled:
                    return "Kissogram requires Push Notifications to be enabled."
                case .UnknownPairingError:
                    return "Unexpected pairing error."
                case .MultipeerCommunicationsError:
                    return "Unexpected multipeer communications error."
                }
            } else {
                return (error as NSError).localizedDescription ?? "Unknown error."
            }
            }()
        alert.addButtonWithTitle("That Sucks!")
        alert.show()
    }
}

extension UILabel {
    class func ultraLight() -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "HelveticaNeue-UltraLight", size: 25)
        label.textColor = UIColor.whiteColor()
        label.numberOfLines = 0
        label.frame = CGRectInset(UIScreen.mainScreen().bounds, 20, 20)
        label.textAlignment = .Center
        return label
    }

    class func thin() -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "HelveticaNeue-Thin", size: 25)
        label.textColor = UIColor.hotPink()
        label.shadowColor = UIColor(white: 1, alpha: 0.77)
        label.shadowOffset = CGSizeMake(0, 1)
        label.textAlignment = .Center
        label.frame = CGRectInset(UIScreen.mainScreen().bounds, 20, 20)
        label.numberOfLines = 0
        return label
    }
}

private class Wrapper: UIView {
    private override func layoutSubviews() {
        let v = subviews[0]
        let f = CGRectInset(bounds, 10, 9)
        v.frame = f
        v.sizeToFit()
        v.frame.size.width = f.size.width
    }
}

func wrap(label: UILabel, margin: CGFloat) -> UIView {
    let wrapper = Wrapper()
    wrapper.addSubview(label)
    return wrapper
}

class CogButton: UIButton {
    required init!(coder: NSCoder = NSCoder.empty()) {
        super.init(coder: coder)
        frame = CGRectMake(0, 0, 44, 44)
        setImage(UIImage(named: "Cog"), forState: .Normal)
    }
}

class BorderedButton: UIButton {
    convenience init(text: String, size: CGFloat = 30) {
        let pink = UIColor.hotPink(alpha: 0.8)

        self.init(frame: CGRectZero)
        setTitle(text, forState: .Normal)
        setTitleColor(pink, forState: .Normal)
        titleLabel!.font = UIFont(name: "HelveticaNeue-UltraLight", size: size)
        setTitleColor(UIColor.pink2(), forState: .Highlighted)
        setBackgroundImage(UIImage(color: pink), forState: .Highlighted)
        layer.cornerRadius = 7.5
        layer.borderColor = pink.CGColor
        layer.borderWidth = 0.66 * size / 30
        clipsToBounds = true
        sizeToFit()
        bounds = CGRectInset(bounds, -16, -3)
    }
}


//////////////////////////////////////////////////////////// CoreGraphics
import CoreGraphics

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: CGRectGetMidX(self), y: CGRectGetMidY(self))
    }
}

class GradientBackgroundView: UIView {
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let ctx = UIGraphicsGetCurrentContext()

        let colors = [UIColor.pink1().CGColor, UIColor.pink2().CGColor]
        let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), colors, [0.0, 1.0])
        let opts = CGGradientDrawingOptions(rawValue: 1 << 1)

        CGContextDrawLinearGradient(ctx, gradient, CGPoint(), CGPoint(x: 0, y: bounds.size.height), opts)
    }
}


//////////////////////////////////////////////////////////////// StoreKit
import PromiseKit
import StoreKit.SKProduct

private var IAPRemoveAdsPrice: String?

class IAP {
    class func products() -> Promise<SKProductsResponse> {
        let pids = Set<String>(arrayLiteral: IAP.RemoveAds.productIdentifier)
        return SKProductsRequest(productIdentifiers: pids).promise()
    }

    class RemoveAds {
        class func fetchPrice() {
            // I wanted to do this with NSObject.load() but Swift disallows it :(
            if !purchased {
                IAP.products().then { response in
                    IAPRemoveAdsPrice = response.products.first?.priceString
                }
            }
        }

        class var productIdentifier: String {
            return "RemoveAds"
        }

        class var purchased: Bool {
            return NSUserDefaults.standardUserDefaults().boolForKey(productIdentifier)
        }

        class var price: String? {
            return IAPRemoveAdsPrice
        }
    }
}

extension SKProduct {
    private var priceString: String? {
        let nf = NSNumberFormatter()
        nf.numberStyle = .CurrencyStyle
        nf.locale = priceLocale
        return nf.stringFromNumber(price)
    }
}
