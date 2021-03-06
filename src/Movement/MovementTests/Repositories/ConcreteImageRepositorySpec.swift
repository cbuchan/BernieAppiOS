import Quick
import Nimble
import WebImage
import BrightFutures
import Result

@testable import Movement

class FakeSDWebImageManager : SDWebImageManager {
    var lastReceivedURL : NSURL!
    var lastReceivedOptions : SDWebImageOptions!
    var lastReceivedCompletionBlock : SDWebImageCompletionWithFinishedBlock!

    override init() {}

    override func downloadImageWithURL(url: NSURL!, options: SDWebImageOptions, progress progressBlock: SDWebImageDownloaderProgressBlock!, completed completedBlock: SDWebImageCompletionWithFinishedBlock!) -> SDWebImageOperation! {
        self.lastReceivedURL = url
        self.lastReceivedOptions = options
        self.lastReceivedCompletionBlock  = completedBlock
        return SDWebImageDownloaderOperation()
    }
}

class ConcreteImageRepositorySpec : QuickSpec {
    var subject : ConcreteImageRepository!
    let webImageManager = FakeSDWebImageManager()
    let expectedURL = NSURL(string: "http://foo.com")!

    override func spec() {
        beforeEach {
            self.subject = ConcreteImageRepository(webImageManager: self.webImageManager)
        }

        describe("fetching an image by URL") {
            var imageFuture: Future<UIImage, NSError>!

            beforeEach {
                imageFuture = self.subject.fetchImageWithURL(self.expectedURL)
            }

            it("should use the image manager to load the image") {
                expect(self.webImageManager.lastReceivedURL).to(beIdenticalTo(self.expectedURL))
            }

            context("when the image downloads successfully") {
                it("should resolve the promise with the image") {
                    let expectedImage = TestUtils.testImageNamed("bernie", type: "jpg")

                    self.webImageManager.lastReceivedCompletionBlock(expectedImage, nil, SDImageCacheType.None, true, self.expectedURL)

                    expect(imageFuture.isSuccess).to(beTrue())
                    expect(imageFuture.value).to(beIdenticalTo(expectedImage))
                }
            }

            context("when the image cannot be downloaded") {
                it("should reject the promise with the error") {
                    let expectedError = NSError(domain: "some domain", code: 666, userInfo: nil)
                    self.webImageManager.lastReceivedCompletionBlock(nil, expectedError, SDImageCacheType.None, true, self.expectedURL)

                    expect(imageFuture.isFailure).to(beTrue())
                    expect(imageFuture.error).to(beIdenticalTo(expectedError))
                }
            }
        }
    }
}
