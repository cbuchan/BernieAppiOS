@testable import Movement
import Quick
import Nimble
import BrightFutures
import Result

private class VideoRepositoryFakeURLProvider: FakeURLProvider {
    override func videoURL() -> NSURL {
        return NSURL(string: "https://youtube.com/bernese/")!
    }
}

private class FakeVideoDeserializer: VideoDeserializer {
    var lastReceivedJSONDictionary: NSDictionary!
    let returnedVideos = [TestUtils.video()]

    func deserializeVideos(jsonDictionary: NSDictionary) -> Array<Video> {
        self.lastReceivedJSONDictionary = jsonDictionary
        return self.returnedVideos
    }
}

class ConcreteVideoRepositorySpec : QuickSpec {
    var subject: ConcreteVideoRepository!
    let jsonClient = FakeJSONClient()
    private let urlProvider = VideoRepositoryFakeURLProvider()
    private let videoDeserializer = FakeVideoDeserializer()
    let operationQueue = FakeOperationQueue()
    var receivedVideos: Array<Video>!
    var receivedError: NSError!

    override func spec() {
        describe("ConcreteVideoRepository") {
            self.subject = ConcreteVideoRepository(
                urlProvider: self.urlProvider,
                jsonClient: self.jsonClient,
                videoDeserializer: self.videoDeserializer,
                operationQueue: self.operationQueue
            )

            describe(".fetchVideos") {
                var videosFuture: Future<Array<Video>, NSError>!

                beforeEach {
                    videosFuture = self.subject.fetchVideos()
                }

                it("makes a single request to the JSON Client with the correct URL, method and parametrs") {
                    expect(self.jsonClient.promisesByURL.count).to(equal(1))
                    expect(self.jsonClient.promisesByURL.keys.first).to(equal(NSURL(string: "https://youtube.com/bernese/")))

                    let expectedHTTPBodyDictionary =
                    [
                        "from": 0, "size": 10,
                        "_source": ["title", "videoId", "description", "created_at"],
                        "sort": [
                            "created_at": ["order": "desc"]
                        ]
                    ]

                    expect(self.jsonClient.lastBodyDictionary).to(equal(expectedHTTPBodyDictionary))
                    expect(self.jsonClient.lastMethod).to(equal("POST"))
                }

                context("when the request to the JSON client succeeds") {
                    let expectedJSONDictionary = NSDictionary();

                    beforeEach {
                        let promise = self.jsonClient.promisesByURL[self.urlProvider.videoURL()]!

                        promise.success(expectedJSONDictionary)
                        expect(self.operationQueue.lastReceivedBlock).toEventuallyNot(beNil())
                    }

                    it("passes the json dictionary to the video deserializer") {
                        expect(self.videoDeserializer.lastReceivedJSONDictionary).to(beIdenticalTo(expectedJSONDictionary))
                    }

                    it("calls the completion handler with the deserialized value objects on the operation queue") {
                        self.operationQueue.lastReceivedBlock()
                        let receivedVideos =  videosFuture.value!
                        expect(receivedVideos.count).to(equal(1))
                        expect(receivedVideos.first!.title).to(equal("Bernie MegaMix"))
                    }
                }

                context("when he request to the JSON client succeeds but does not resolve with a JSON dictioanry") {
                    beforeEach {
                        let promise = self.jsonClient.promisesByURL[self.urlProvider.videoURL()]!

                        promise.success([1,2,3])
                        expect(self.operationQueue.lastReceivedBlock).toEventuallyNot(beNil())
                    }

                    it("calls the completion handler with an error") {
                        self.operationQueue.lastReceivedBlock()
                        expect(videosFuture.error).notTo(beNil())
                    }
                }

                context("when the request to the JSON client fails") {
                    it("forwards the error to the caller on the operation queue") {
                        let promise = self.jsonClient.promisesByURL[self.urlProvider.videoURL()]!
                        let expectedError = NSError(domain: "somedomain", code: 666, userInfo: nil)
                        promise.failure(expectedError)
                        expect(self.operationQueue.lastReceivedBlock).toEventuallyNot(beNil())

                        self.operationQueue.lastReceivedBlock()
                        expect(videosFuture.error).to(beIdenticalTo(expectedError))
                    }
                }
            }
        }
    }
}
