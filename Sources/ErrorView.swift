import TSMarkdownParser
import CloudKit
import UIKit

class ErrorView: UIView {
    private let label: UILabel
    let retry: UIButton

    init(error: ErrorType) {
        label = UILabel()
        retry = BorderedButton(text: "Try Again")

        super.init(frame: UIScreen.mainScreen().bounds)

        label.attributedText = (error as NSError).attributedString()
        label.textColor = UIColor(hue:0.93, saturation:1, brightness:1, alpha:1)
        label.numberOfLines = 0
        label.textAlignment = .Center

        addSubview(label)
        addSubview(retry)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        label.frame = CGRectInset(bounds, 20, 20)
        label.frame.size.height -= retry.bounds.size.height + 20

        retry.center = bounds.center
        retry.frame.origin.y = bounds.size.height - retry.frame.size.height - 20
    }
}


extension NSError {
    private func attributedString() -> NSAttributedString {
        let parser = TSMarkdownParser.standardParser()
        parser.h1Font = UIFont(name: "HelveticaNeue-UltraLight", size: 80)
        parser.h2Font = UIFont(name: "HelveticaNeue-UltraLight", size: 40)
        parser.paragraphFont = UIFont(name: "HelveticaNeue-Thin", size: 7)

        func detail() -> String {
            switch (domain, code) {
            case (CKErrorDomain, 4):
                return "Please check that *iCloud is enabled* in your iPhone Settings."
            case (CKErrorDomain, 9):
                return "Please check that *iCloud Drive* is enabled in your iPhone Settings."
            default:
                return localizedDescription
            }
        }
        
        let text = "# Error\n\n## \(detail())\n\n\(self)"

        return parser.attributedStringFromMarkdown(text)
    }
}
