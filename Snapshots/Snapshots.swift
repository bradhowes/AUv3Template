import XCTest

class Snapshots: XCTestCase {
    var app: XCUIApplication!
    var suffix: String!

    func snap(_ title: String) { snapshot(title + suffix) }

    func initialize(_ orientation: UIDeviceOrientation) {
        suffix = orientation.isPortrait ? "-Portrait" : "-Landscape"
        XCUIDevice.shared.orientation = orientation
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))
    }

    func run(_ orientation: UIDeviceOrientation, _ title: String, setup: () -> Void) {
        initialize(orientation)
        setup()
        snap(title)
    }

    func showMainView() {
        let mainView = app.otherElements["MainView"]
        guard mainView.exists == false else { return }
        XCTAssert(mainView.waitForExistence(timeout: 5))
    }


    func testLPFPortrait() { run(.portrait, "LPF") { showMainView() } }
    func testLPFLandscape() { run(.landscapeLeft, "LPF") { showMainView() } }
}

extension XCUIApplication {
    private struct Constants {
        // Half way across the screen and 10% from top
        static let topOffset = CGVector(dx: 0.5, dy: 0.1)

        // Half way across the screen and 90% from top
        static let bottomOffset = CGVector(dx: 0.5, dy: 0.9)
    }

    var screenTopCoordinate: XCUICoordinate {
        windows.firstMatch.coordinate(withNormalizedOffset: Constants.topOffset)
    }

    var screenBottomCoordinate: XCUICoordinate {
        windows.firstMatch.coordinate(withNormalizedOffset: Constants.bottomOffset)
    }

    func scrollDownToElement(element: XCUIElement, maxScrolls: Int = 5) {
        for _ in 0..<maxScrolls {
            if element.exists && element.isHittable { element.scrollToTop(); break }
            scrollDown()
        }
    }

    func scrollDown() {
        screenBottomCoordinate.press(forDuration: 0.1, thenDragTo: screenTopCoordinate)
    }
}

extension XCUIElement {
    func scrollToTop() {
        let topCoordinate = XCUIApplication().screenTopCoordinate
        let elementCoordinate = coordinate(withNormalizedOffset: .zero)

        // Adjust coordinate so that the drag is straight up, otherwise
        // an embedded horizontal scrolling element will get scrolled instead
        let delta = topCoordinate.screenPoint.x - elementCoordinate.screenPoint.x
        let deltaVector = CGVector(dx: delta, dy: 0.0)

        elementCoordinate.withOffset(deltaVector).press(forDuration: 0.1, thenDragTo: topCoordinate)
    }
}
