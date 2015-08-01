import PromiseKit
import UIKit

class SwishLabel: UIView {
    private var label = MotionBlurLabel(text: "")
    private var animation = Promise<Void>()

    func clearAfter(duration: NSTimeInterval) {
        let text = label.text
        after(duration).then { _ -> Void in
            if text == self.label.text && !self.animation.pending {
                self.text = ""
            }
        }
    }

    var text: String {
        set {
            let newLabel = MotionBlurLabel(text: newValue)
            newLabel.frame = bounds;

            if let oldLabel = label {
                label = newLabel
                newLabel.isBlurred = true

                let duration = 0.5

                animation = animation.then { _ -> Promise<Void> in
                    let W = self.frame.size.width * 1.3;

                    let d = duration * 2 / 5
                    let p1 = UIView.animate(duration: d, delay: d, options: UIViewAnimationOptions.CurveLinear, animations: {
                        oldLabel.alpha = 0
                        oldLabel.center = CGPoint(x: oldLabel.center.x - 30, y: oldLabel.center.y)
                    }).then { _ in
                        oldLabel.removeFromSuperview()
                    }

                    let oldcenter = newLabel.center
                    newLabel.center = CGPointMake(oldcenter.x + W, oldcenter.y)
                    self.addSubview(newLabel)

                    let p2 = UIView.animate(duration: d, delay: 0, options: .CurveLinear, animations: {
                        newLabel.center = oldcenter
                    }).asVoid()

                    let p3 = after(d).then {
                        return UIView.animate(duration: duration/5, animations: {
                            newLabel.isBlurred = false
                        })
                    }.asVoid()

                    let p4 = after(0.75).asVoid()

                    return when(p1, p2, p3, p4).asVoid() //FIXME PMK2
                }
            } else {
                label = newLabel
                addSubview(newLabel)
            }
        }

        get {
            return ""
        }
    }

    override func layoutSubviews() {
        for ll in self.subviews as! [MotionBlurLabel] {
            if !ll.isBlurred && ll.alpha == 1 {
                ll.frame = self.bounds
            }
        }
    }

    override func didMoveToSuperview() {
        backgroundColor = superview?.backgroundColor
    }
}
