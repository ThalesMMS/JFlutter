import Foundation

/// View model that orchestrates window/level interactions for volumetric and MPR modes.
public final class ViewerViewModel {
  private let sessionState: VolumetricSessionState

  /// Window/level persisted for volumetric rendering.
  public private(set) var volumetricWWLState: HuWindow?

  /// Dedicated window/level persisted for MPR rendering.
  public private(set) var mprWWLState: HuWindow?

  public init(sessionState: VolumetricSessionState) {
    self.sessionState = sessionState
    volumetricWWLState = sessionState.volumeHuWindow
    mprWWLState = sessionState.currentMprHuWindow
  }

  /// Applies a volumetric window/level preserving the independent MPR state.
  public func applyVolumetricWindowLevel(_ window: HuWindow?) {
    volumetricWWLState = window
    sessionState.setHuWindow(window)
  }

  /// Applies a dedicated MPR window/level without touching the volumetric configuration.
  public func applyMprWindowLevel(_ window: HuWindow?) {
    mprWWLState = window
    sessionState.setMprHuWindow(window)
  }

  /// Returns the active MPR window/level, considering the cached state and the session defaults.
  public var currentMprWindowLevelState: HuWindow? {
    mprWWLState ?? sessionState.currentMprHuWindow
  }
}
