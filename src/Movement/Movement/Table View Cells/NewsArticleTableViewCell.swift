import UIKit
import PureLayout


class NewsArticleTableViewCell: UITableViewCell {
    let titleLabel = UILabel.newAutoLayoutView()
    let excerptLabel = UILabel.newAutoLayoutView()
    let dateLabel = UILabel.newAutoLayoutView()
    let newsImageView = UIImageView.newAutoLayoutView()
    let disclosureView = DisclosureIndicatorView.newAutoLayoutView()

    private var excerptRightEdge: NSLayoutConstraint?
    private let defaultMargin: CGFloat
    private let rightMarginWithoutImage: CGFloat
    private let rightMarginWithImage: CGFloat

    var newsImageVisible: Bool {
        get {
            return !self.newsImageView.hidden
        }
        set {
            self.newsImageView.hidden = !newValue
            self.excerptRightEdge!.constant = newValue ? rightMarginWithImage : rightMarginWithoutImage
            self.layoutSubviews()
        }
    }


    private let containerView = UIView.newAutoLayoutView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.defaultMargin = 20
        self.rightMarginWithoutImage = -self.defaultMargin
        self.rightMarginWithImage = -(108 + self.defaultMargin + self.defaultMargin)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .None

        self.contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(disclosureView)
        containerView.addSubview(excerptLabel)
        containerView.addSubview(newsImageView)

        self.backgroundColor = UIColor.clearColor()

        containerView.backgroundColor = UIColor.whiteColor()

        self.accessoryType = .None
        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
        self.preservesSuperviewLayoutMargins = false

        titleLabel.numberOfLines = 3

        dateLabel.textAlignment = .Right
        disclosureView.backgroundColor = UIColor.whiteColor()

        excerptLabel.numberOfLines = 4
        excerptLabel.adjustsFontSizeToFitWidth = false
        excerptLabel.lineBreakMode = .ByTruncatingTail

        newsImageView.backgroundColor = UIColor.grayColor()

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.autoPinEdgeToSuperviewEdge(.Top, withInset: 11)
        containerView.autoPinEdgeToSuperviewEdge(.Left)
        containerView.autoPinEdgeToSuperviewEdge(.Right)
        containerView.autoPinEdgeToSuperviewEdge(.Bottom)

        titleLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: defaultMargin)
        titleLabel.autoPinEdgeToSuperviewEdge(.Left, withInset: defaultMargin)
        titleLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 50)

        dateLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 25)
        dateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: titleLabel, withOffset: 5)
        dateLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: defaultMargin)

        disclosureView.autoPinEdge(.Top, toEdge: .Top, ofView: dateLabel, withOffset: 1)
        disclosureView.autoPinEdge(.Left, toEdge: .Right, ofView: dateLabel, withOffset: 5)
        disclosureView.autoPinEdgeToSuperviewEdge(.Right)
        disclosureView.autoSetDimension(.Height, toSize: 20)

        newsImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: titleLabel, withOffset: 5)
        newsImageView.autoPinEdgeToSuperviewEdge(.Right, withInset: defaultMargin)
        newsImageView.autoSetDimension(.Width, toSize: 108)
        newsImageView.autoSetDimension(.Height, toSize: 60)
        newsImageView.clipsToBounds = true
        newsImageView.contentMode = .ScaleAspectFill

        excerptLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: titleLabel, withOffset: 5)
        excerptLabel.autoPinEdgeToSuperviewEdge(.Left, withInset: defaultMargin)
        self.excerptRightEdge = excerptLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: defaultMargin + 108 + defaultMargin)
        excerptLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: defaultMargin)
    }
}
