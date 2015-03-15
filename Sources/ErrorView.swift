import UIKit
import TSMarkdownParser

class ErrorView: UIView {
    private let label = UILabel()
    let retry = BorderedButton(text: "Try Again")

    init(error: NSError) {
        super.init(frame: UIScreen.mainScreen().bounds)

        label.attributedText = error.attributedString()
        label.textColor = UIColor(hue:0.93, saturation:1, brightness:1, alpha:1)
        label.numberOfLines = 0
        label.textAlignment = .Center
        addSubview(label)

        addSubview(retry)
    }

    required init(coder aDecoder: NSCoder) {
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

        let text = "# Error\n\n## \(localizedDescription)\n\n\(self)"

        return parser.attributedStringFromMarkdown(text)
    }
}