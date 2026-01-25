//
//  settings_model.dart
//  JFlutter
//
//  Estrutura leve que representa as preferências persistidas do aplicativo,
//  controlando símbolos especiais, preferências de interface e tamanhos de
//  elementos. Garante valores padrão coesos, permite cópias imutáveis e facilita
//  comparações para atualizar provedores de configuração.
//
//  Thales Matheus Mendonça Santos - October 2025
//
/// Model representing persisted application settings.
class SettingsModel {
  /// Symbol used to represent the empty string.
  final String emptyStringSymbol;

  /// Symbol used to represent epsilon transitions.
  final String epsilonSymbol;

  /// Theme mode preference (system, light, dark).
  final String themeMode;

  /// Whether to display the grid on the canvas.
  final bool showGrid;

  /// Whether to display coordinates on the canvas.
  final bool showCoordinates;

  /// Whether autosave is enabled.
  final bool autoSave;

  /// Whether to display tooltips.
  final bool showTooltips;

  /// Size of the grid in logical pixels.
  final double gridSize;

  /// Size of nodes in logical pixels.
  final double nodeSize;

  /// Base font size in the interface.
  final double fontSize;

  /// Animation speed multiplier (1.0 = normal, 0.5 = slow, 2.0 = fast).
  final double animationSpeed;

  const SettingsModel({
    this.emptyStringSymbol = 'λ',
    this.epsilonSymbol = 'ε',
    this.themeMode = 'system',
    this.showGrid = true,
    this.showCoordinates = false,
    this.autoSave = true,
    this.showTooltips = true,
    this.gridSize = 20.0,
    this.nodeSize = 30.0,
    this.fontSize = 14.0,
    this.animationSpeed = 1.0,
  });

  /// Creates a new [SettingsModel] with updated values.
  SettingsModel copyWith({
    String? emptyStringSymbol,
    String? epsilonSymbol,
    String? themeMode,
    bool? showGrid,
    bool? showCoordinates,
    bool? autoSave,
    bool? showTooltips,
    double? gridSize,
    double? nodeSize,
    double? fontSize,
    double? animationSpeed,
  }) {
    return SettingsModel(
      emptyStringSymbol: emptyStringSymbol ?? this.emptyStringSymbol,
      epsilonSymbol: epsilonSymbol ?? this.epsilonSymbol,
      themeMode: themeMode ?? this.themeMode,
      showGrid: showGrid ?? this.showGrid,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      autoSave: autoSave ?? this.autoSave,
      showTooltips: showTooltips ?? this.showTooltips,
      gridSize: gridSize ?? this.gridSize,
      nodeSize: nodeSize ?? this.nodeSize,
      fontSize: fontSize ?? this.fontSize,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is SettingsModel &&
        other.emptyStringSymbol == emptyStringSymbol &&
        other.epsilonSymbol == epsilonSymbol &&
        other.themeMode == themeMode &&
        other.showGrid == showGrid &&
        other.showCoordinates == showCoordinates &&
        other.autoSave == autoSave &&
        other.showTooltips == showTooltips &&
        other.gridSize == gridSize &&
        other.nodeSize == nodeSize &&
        other.fontSize == fontSize &&
        other.animationSpeed == animationSpeed;
  }

  @override
  int get hashCode => Object.hash(
    emptyStringSymbol,
    epsilonSymbol,
    themeMode,
    showGrid,
    showCoordinates,
    autoSave,
    showTooltips,
    gridSize,
    nodeSize,
    fontSize,
    animationSpeed,
  );
}
