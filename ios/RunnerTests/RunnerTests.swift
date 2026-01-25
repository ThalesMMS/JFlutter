import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testFlutterAppDelegateSetsUpWindowAndRootController() {
    let application = UIApplication.shared
    let appDelegate = AppDelegate()

    let didFinishLaunching = appDelegate.application(application, didFinishLaunchingWithOptions: nil)

    XCTAssertTrue(didFinishLaunching, "AppDelegate should report a successful launch")
    XCTAssertNotNil(appDelegate.window, "AppDelegate should create the main window")

    let rootViewController = appDelegate.window?.rootViewController
    XCTAssertNotNil(rootViewController, "AppDelegate should assign a rootViewController")
    XCTAssertTrue(
      rootViewController is FlutterViewController,
      "Root view controller should be a FlutterViewController"
    )

    let flutterViewController = rootViewController as? FlutterViewController
    flutterViewController?.loadViewIfNeeded()
    XCTAssertNotNil(flutterViewController?.view, "FlutterViewController should load its view successfully")
  }
}
