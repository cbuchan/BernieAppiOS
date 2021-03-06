import UIKit
import Quick
import Nimble
@testable import Movement



class NewsArticleFakeTheme : FakeTheme {
    override func newsArticleDateFont() -> UIFont { return UIFont.boldSystemFontOfSize(20) }
    override func newsArticleDateColor() -> UIColor { return UIColor.magentaColor() }
    override func newsArticleTitleFont() -> UIFont { return UIFont.italicSystemFontOfSize(13) }
    override func newsArticleTitleColor() -> UIColor { return UIColor.brownColor() }
    override func newsArticleBodyFont() -> UIFont { return UIFont.systemFontOfSize(3) }
    override func newsArticleBodyColor() -> UIColor { return UIColor.yellowColor() }
    override func defaultBackgroundColor() -> UIColor { return UIColor.orangeColor() }
    override func attributionFont() -> UIFont { return UIFont.boldSystemFontOfSize(111) }
    override func attributionTextColor() -> UIColor { return UIColor.greenColor() }
    override func defaultButtonBackgroundColor() -> UIColor { return UIColor.redColor() }
    override func defaultButtonTextColor() -> UIColor { return UIColor.blueColor() }
    override func defaultButtonFont() -> UIFont { return UIFont.boldSystemFontOfSize(222) }

}

class NewsArticleControllerSpec : QuickSpec {
    var subject: NewsArticleController!
    let newsArticleImageURL = NSURL(string: "http://a.com")!
    let newsArticleURL = NSURL(string: "http//b.com")!
    let newsArticleDate = NSDate(timeIntervalSince1970: 1441081523)
    var newsArticle: NewsArticle!
    var imageRepository: FakeImageRepository!
    var timeIntervalFormatter: FakeTimeIntervalFormatter!
    var analyticsService: FakeAnalyticsService!
    var urlOpener: FakeURLOpener!
    var urlAttributionPresenter: FakeURLAttributionPresenter!
    let theme = NewsArticleFakeTheme()

    override func spec() {
        describe("NewsArticleController") {
            beforeEach {
                self.imageRepository = FakeImageRepository()
                self.timeIntervalFormatter = FakeTimeIntervalFormatter()
                self.analyticsService = FakeAnalyticsService()
                self.urlOpener = FakeURLOpener()
                self.urlAttributionPresenter = FakeURLAttributionPresenter()
            }

            context("with a standard news item") {
                beforeEach {
                    self.newsArticle = NewsArticle(title: "some title", date: self.newsArticleDate, body: "some body text", excerpt: "excerpt", imageURL: self.newsArticleImageURL, url:self.newsArticleURL)

                    self.subject = NewsArticleController(
                        newsArticle: self.newsArticle,
                        imageRepository: self.imageRepository,
                        timeIntervalFormatter: self.timeIntervalFormatter,
                        analyticsService: self.analyticsService,
                        urlOpener: self.urlOpener,
                        urlAttributionPresenter: self.urlAttributionPresenter,
                        theme: self.theme
                    )
                }

                it("tracks taps on the back button with the analytics service") {
                    self.subject.didMoveToParentViewController(nil)

                    expect(self.analyticsService.lastBackButtonTapScreen).to(equal("News Item"))
                    let expectedAttributes = [ AnalyticsServiceConstants.contentIDKey: self.newsArticle.url.absoluteString]
                    expect(self.analyticsService.lastBackButtonTapAttributes! as? [String: String]).to(equal(expectedAttributes))
                }

                it("should hide the tab bar when pushed") {
                    expect(self.subject.hidesBottomBarWhenPushed).to(beTrue())
                }

                describe("when the view loads") {
                    beforeEach {
                        self.subject.view.layoutIfNeeded()
                    }

                    it("has a share button on the navigation item") {
                        let shareBarButtonItem = self.subject.navigationItem.rightBarButtonItem!
                        expect(shareBarButtonItem.title).to(equal("Share"))
                    }

                    it("sets up the body text view not to be editable") {
                        expect(self.subject.bodyTextView.editable).to(beFalse())
                    }

                    describe("tapping on the share button") {
                        beforeEach {
                            self.subject.navigationItem.rightBarButtonItem!.tap()
                        }

                        it("should present an activity view controller for sharing the story URL") {

                            let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                            let activityItems = activityViewControler.activityItems()

                            expect(activityItems.count).to(equal(1))
                            expect(activityItems.first as? NSURL).to(beIdenticalTo(self.newsArticleURL))
                        }

                        it("logs that the user tapped share") {
                            expect(self.analyticsService.lastCustomEventName).to(equal("Began Share"))
                            let expectedAttributes = [
                                AnalyticsServiceConstants.contentIDKey: self.newsArticle.url.absoluteString,
                                AnalyticsServiceConstants.contentNameKey: self.newsArticle.title,
                                AnalyticsServiceConstants.contentTypeKey: "News Article"
]
                            expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                        }

                        context("and the user completes the share succesfully") {
                            it("tracks the share via the analytics service") {
                                let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                                activityViewControler.completionWithItemsHandler!("Some activity", true, nil, nil)

                                expect(self.analyticsService.lastShareActivityType).to(equal("Some activity"))
                                expect(self.analyticsService.lastShareContentName).to(equal(self.newsArticle.title))
                                expect(self.analyticsService.lastShareContentType).to(equal(AnalyticsServiceContentType.NewsArticle))
                                expect(self.analyticsService.lastShareID).to(equal(self.newsArticleURL.absoluteString))
                            }
                        }

                        context("and the user cancels the share") {
                            it("tracks the share cancellation via the analytics service") {
                                let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                                activityViewControler.completionWithItemsHandler!(nil, false, nil, nil)

                                expect(self.analyticsService.lastCustomEventName).to(equal("Cancelled Share"))
                                let expectedAttributes = [
                                    AnalyticsServiceConstants.contentIDKey: self.newsArticle.url.absoluteString,
                                    AnalyticsServiceConstants.contentNameKey: self.newsArticle.title,
                                    AnalyticsServiceConstants.contentTypeKey: "News Article"
                                ]
                                expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                            }
                        }

                        context("and there is an error when sharing") {
                            it("tracks the error via the analytics service") {
                                let expectedError = NSError(domain: "a", code: 0, userInfo: nil)
                                let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                                activityViewControler.completionWithItemsHandler!("asdf", true, nil, expectedError)

                                expect(self.analyticsService.lastError as NSError).to(beIdenticalTo(expectedError))
                                expect(self.analyticsService.lastErrorContext).to(equal("Failed to share News Item"))
                            }
                        }
                    }

                    it("has a scroll view containing the UI elements") {
                        expect(self.subject.view.subviews.count).to(equal(1))
                        let scrollView = self.subject.view.subviews.first as! UIScrollView

                        expect(scrollView).to(beAnInstanceOf(UIScrollView.self))
                        expect(scrollView.subviews.count).to(equal(1))

                        let containerView = scrollView.subviews.first!

                        expect(containerView.subviews.count).to(equal(6))

                        let containerViewSubViews = containerView.subviews

                        expect(containerViewSubViews.contains(self.subject.titleButton)).to(beTrue())
                        expect(containerViewSubViews.contains(self.subject.bodyTextView)).to(beTrue())
                        expect(containerViewSubViews.contains(self.subject.dateLabel)).to(beTrue())
                        expect(containerViewSubViews.contains(self.subject.storyImageView)).to(beTrue())
                    }

                    it("displays the title from the news item as a button") {
                        expect(self.subject.titleButton.titleForState(.Normal)).to(equal("some title"))
                    }

                    describe("tapping on the title button") {
                        beforeEach {
                            self.subject.titleButton.tap()
                        }

                        it("opens the original issue in safari") {
                            expect(self.urlOpener.lastOpenedURL).to(beIdenticalTo(self.newsArticle.url))
                        }

                        it("logs that the user tapped view original") {
                            expect(self.analyticsService.lastCustomEventName).to(equal("Tapped title on News Item"))
                            let expectedAttributes = [ AnalyticsServiceConstants.contentIDKey: self.newsArticle.url.absoluteString]
                            expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                        }
                    }

                    it("displays the story body") {
                        expect(self.subject.bodyTextView.text).to(equal("some body text"))
                    }

                    it("displays the date using the human date formatter") {
                        expect(self.timeIntervalFormatter.lastFormattedDate).to(beIdenticalTo(self.newsArticleDate))
                        expect(self.subject.dateLabel.text).to(equal("human date"))
                    }

                    it("uses the presenter to get attribution text for the issue") {
                        expect(self.urlAttributionPresenter.lastPresentedURL).to(beIdenticalTo(self.newsArticle.url))
                        expect(self.subject.attributionLabel.text).to(equal(self.urlAttributionPresenter.returnedText))
                    }

                    it("has a button to view the original issue") {
                        expect(self.subject.viewOriginalButton.titleForState(.Normal)).to(equal("View Original"))
                    }

                    describe("tapping on the view original button") {
                        beforeEach {
                            self.subject.viewOriginalButton.tap()
                        }

                        it("opens the original issue in safari") {
                            expect(self.urlOpener.lastOpenedURL).to(beIdenticalTo(self.newsArticle.url))
                        }

                        it("logs that the user tapped view original") {
                            expect(self.analyticsService.lastCustomEventName).to(equal("Tapped 'View Original' on News Item"))
                            let expectedAttributes = [ AnalyticsServiceConstants.contentIDKey: self.newsArticle.url.absoluteString]
                            expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                        }
                    }

                    it("makes a request for the story's image") {
                        expect(self.imageRepository.lastReceivedURL).to(beIdenticalTo(self.newsArticleImageURL))
                    }

                    it("styles the views according to the theme") {
                        expect(self.subject.view.backgroundColor).to(equal(UIColor.orangeColor()))
                        expect(self.subject.dateLabel.font).to(equal(UIFont.boldSystemFontOfSize(20)))
                        expect(self.subject.dateLabel.textColor).to(equal(UIColor.magentaColor()))
                        expect(self.subject.titleButton.titleLabel!.font).to(equal(UIFont.italicSystemFontOfSize(13)))
                        expect(self.subject.titleButton.titleColorForState(.Normal)).to(equal(UIColor.brownColor()))
                        expect(self.subject.bodyTextView.font).to(equal(UIFont.systemFontOfSize(3)))
                        expect(self.subject.bodyTextView.textColor).to(equal(UIColor.yellowColor()))
                        expect(self.subject.attributionLabel.textColor).to(equal(UIColor.greenColor()))
                        expect(self.subject.attributionLabel.font).to(equal(UIFont.boldSystemFontOfSize(111)))
                        expect(self.subject.viewOriginalButton.backgroundColor).to(equal(UIColor.redColor()))
                        expect(self.subject.viewOriginalButton.titleColorForState(.Normal)).to(equal(UIColor.blueColor()))
                    }

                    context("when the request for the story's image succeeds") {
                        it("displays the image") {
                            let storyImage = TestUtils.testImageNamed("bernie", type: "jpg")
                            let expectedImageData = UIImagePNGRepresentation(storyImage)

                            self.imageRepository.lastRequestPromise.success(storyImage)

                            let storyImageData = UIImagePNGRepresentation(self.subject.storyImageView.image!)

                            expect(storyImageData).to(equal(expectedImageData))
                        }
                    }

                    context("when the request for the story's image fails") {
                        it("removes the image view from the container") {
                            self.imageRepository.lastRequestPromise.failure(NSError(domain: "", code: 0, userInfo: nil))
                            let scrollView = self.subject.view.subviews.first!
                            let containerView = scrollView.subviews.first!
                            let containerViewSubViews = containerView.subviews

                            expect(containerViewSubViews.contains(self.subject.storyImageView)).to(beFalse())
                        }
                    }
                }
            }

            context("with a news item that lacks an image") {
                beforeEach {
                    let newsArticleDate = NSDate(timeIntervalSince1970: 1441081523)
                    let newsArticle = NewsArticle(title: "some title", date: newsArticleDate, body: "some body text", excerpt: "excerpt", imageURL: nil, url:self.newsArticleURL)

                    self.subject = NewsArticleController(
                        newsArticle: newsArticle,
                        imageRepository: self.imageRepository,
                        timeIntervalFormatter: self.timeIntervalFormatter,
                        analyticsService: self.analyticsService,
                        urlOpener: self.urlOpener,
                        urlAttributionPresenter: self.urlAttributionPresenter,
                        theme: self.theme
                    )

                    self.subject.view.layoutIfNeeded()
                }

                it("should not make a request for the story's image") {
                    expect(self.imageRepository.imageRequested).to(beFalse())
                }

                it("removes the image view from the container") {
                    let scrollView = self.subject.view.subviews.first!
                    let containerView = scrollView.subviews.first!
                    let containerViewSubViews = containerView.subviews

                    expect(containerViewSubViews.contains(self.subject.storyImageView)).to(beFalse())
                }
            }
        }
    }
}
