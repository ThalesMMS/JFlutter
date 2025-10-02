import XCTest
@testable import Runner

private final class MockHuWindowController: HuWindowControlling {
  var huWindow: HuWindow?
}

final class ViewerPanZoomStabilityTests: XCTestCase {
  func testSettingMprWindowDoesNotAlterVolumetricState() {
    let volumetricController = MockHuWindowController()
    let mprController = MockHuWindowController()
    let state = VolumetricSessionState(volumetricController: volumetricController)
    state.prepareMprControllers([mprController], metadataWindow: HuWindow(width: 1200, level: 40))

    let volumetricWindow = HuWindow(width: 400, level: 50)
    state.setHuWindow(volumetricWindow)
    let mprWindow = HuWindow(width: 1600, level: 60)
    state.setMprHuWindow(mprWindow)

    XCTAssertEqual(state.volumeHuWindow, volumetricWindow)
    XCTAssertEqual(state.currentMprHuWindow, mprWindow)
    XCTAssertEqual(volumetricController.huWindow, volumetricWindow)
    XCTAssertEqual(mprController.huWindow, mprWindow)
  }

  func testSettingVolumetricWindowDoesNotAlterMprState() {
    let volumetricController = MockHuWindowController()
    let mprController = MockHuWindowController()
    let state = VolumetricSessionState(volumetricController: volumetricController)
    let mprWindow = HuWindow(width: 1800, level: 70)
    state.prepareMprControllers([mprController], metadataWindow: HuWindow(width: 900, level: 30))
    state.setMprHuWindow(mprWindow)

    let volumetricWindow = HuWindow(width: 500, level: 45)
    state.setHuWindow(volumetricWindow)

    XCTAssertEqual(state.currentMprHuWindow, mprWindow)
    XCTAssertEqual(mprController.huWindow, mprWindow)
  }

  func testPrepareMprControllersUsesOverrideWhenPresent() {
    let firstMprController = MockHuWindowController()
    let secondMprController = MockHuWindowController()
    let state = VolumetricSessionState()
    let override = HuWindow(width: 2000, level: 80)
    state.setMprHuWindow(override)

    state.prepareMprControllers([firstMprController, secondMprController], metadataWindow: HuWindow(width: 400, level: 10))

    XCTAssertEqual(firstMprController.huWindow, override)
    XCTAssertEqual(secondMprController.huWindow, override)
  }

  func testPrepareMprControllersFallsBackToMetadata() {
    let firstMprController = MockHuWindowController()
    let secondMprController = MockHuWindowController()
    let state = VolumetricSessionState()
    let metadata = HuWindow(width: 350, level: -20)

    state.prepareMprControllers([firstMprController, secondMprController], metadataWindow: metadata)

    XCTAssertEqual(firstMprController.huWindow, metadata)
    XCTAssertEqual(secondMprController.huWindow, metadata)
  }

  func testViewModelKeepsIndependentStates() {
    let volumetricController = MockHuWindowController()
    let mprController = MockHuWindowController()
    let state = VolumetricSessionState(volumetricController: volumetricController)
    state.prepareMprControllers([mprController], metadataWindow: nil)
    let viewModel = ViewerViewModel(sessionState: state)

    let volumetricWindow = HuWindow(width: 450, level: 20)
    viewModel.applyVolumetricWindowLevel(volumetricWindow)
    XCTAssertEqual(viewModel.volumetricWWLState, volumetricWindow)
    XCTAssertNil(viewModel.mprWWLState)

    let mprWindow = HuWindow(width: 1750, level: 30)
    viewModel.applyMprWindowLevel(mprWindow)
    XCTAssertEqual(viewModel.mprWWLState, mprWindow)
    XCTAssertEqual(viewModel.currentMprWindowLevelState, mprWindow)
    XCTAssertEqual(state.volumeHuWindow, volumetricWindow)
    XCTAssertEqual(state.currentMprHuWindow, mprWindow)
  }
}
