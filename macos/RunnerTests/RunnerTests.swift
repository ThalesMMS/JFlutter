import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {

  func testFlutterWindowIsConfiguredWithFlutterViewController() {
    // Access the shared application instance to match the runner's startup path.
    let app = NSApplication.shared
    XCTAssertNotNil(app)

    // Instantiate the runner window and trigger the wiring performed in awakeFromNib.
    let window = MainFlutterWindow()
    defer { window.close() }

    window.awakeFromNib()

    // The runner should host a FlutterViewController after setup.
    XCTAssertTrue(window.contentViewController is FlutterViewController)
  }

}
