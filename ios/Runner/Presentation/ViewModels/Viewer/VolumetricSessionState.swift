import Foundation

/// Represents an HU (Hounsfield Units) window level configuration.
public struct HuWindow: Equatable {
  public var width: Double
  public var level: Double

  public init(width: Double, level: Double) {
    self.width = width
    self.level = level
  }
}

/// Abstraction describing a component capable of reacting to HU window updates.
public protocol HuWindowControlling: AnyObject {
  var huWindow: HuWindow? { get set }
}

/// Holds the volumetric viewer session state, keeping independent window ranges for the
/// volume rendering and the MPR controllers.
public final class VolumetricSessionState {
  public weak var volumetricController: (any HuWindowControlling)?
  private(set) var mprControllers: [HuWindowControlling] = []

  /// Persists the HU window applied on the volumetric controller so it can be reused when
  /// rebuilding the pipeline.
  public private(set) var volumeHuWindow: HuWindow?

  /// Tracks the latest HU window that should be applied on MPR controllers without touching the
  /// volumetric controller configuration.
  public private(set) var currentMprHuWindow: HuWindow?

  public init(volumetricController: (any HuWindowControlling)? = nil) {
    self.volumetricController = volumetricController
  }

  /// Applies the HU window exclusively on volumetric rendering, preserving the HU range in memory
  /// for future reconfiguration.
  public func setHuWindow(_ window: HuWindow?) {
    volumeHuWindow = window
    volumetricController?.huWindow = window
  }

  /// Updates only the cached HU window for MPR controllers and pushes the change to them without
  /// altering the volumetric HU state.
  public func setMprHuWindow(_ window: HuWindow?) {
    currentMprHuWindow = window
    for controller in mprControllers {
      controller.huWindow = window
    }
  }

  /// Stores the supplied MPR controllers and applies the cached HU window, if any. When no
  /// override is available we fall back to the dataset metadata.
  public func prepareMprControllers(
    _ controllers: [HuWindowControlling],
    metadataWindow: HuWindow?
  ) {
    mprControllers = controllers

    if let override = currentMprHuWindow {
      controllers.forEach { $0.huWindow = override }
    } else if let metadataWindow {
      controllers.forEach { $0.huWindow = metadataWindow }
    }
  }
}
