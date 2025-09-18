/// Represents a rule in an L-system
class LSystemRule {
  /// The symbol that this rule applies to
  final String symbol;
  
  /// The replacement string for this symbol
  final String replacement;
  
  /// The probability of this rule being applied (for stochastic L-systems)
  final double probability;
  
  /// Whether this rule is active
  final bool isActive;
  
  /// Additional context for context-sensitive L-systems
  final String? leftContext;
  final String? rightContext;

  const LSystemRule({
    required this.symbol,
    required this.replacement,
    this.probability = 1.0,
    this.isActive = true,
    this.leftContext,
    this.rightContext,
  });

  /// Creates a copy of this rule with updated properties
  LSystemRule copyWith({
    String? symbol,
    String? replacement,
    double? probability,
    bool? isActive,
    String? leftContext,
    String? rightContext,
  }) {
    return LSystemRule(
      symbol: symbol ?? this.symbol,
      replacement: replacement ?? this.replacement,
      probability: probability ?? this.probability,
      isActive: isActive ?? this.isActive,
      leftContext: leftContext ?? this.leftContext,
      rightContext: rightContext ?? this.rightContext,
    );
  }

  /// Converts the rule to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'replacement': replacement,
      'probability': probability,
      'isActive': isActive,
      'leftContext': leftContext,
      'rightContext': rightContext,
    };
  }

  /// Creates a rule from a JSON representation
  factory LSystemRule.fromJson(Map<String, dynamic> json) {
    return LSystemRule(
      symbol: json['symbol'] as String,
      replacement: json['replacement'] as String,
      probability: (json['probability'] as num?)?.toDouble() ?? 1.0,
      isActive: json['isActive'] as bool? ?? true,
      leftContext: json['leftContext'] as String?,
      rightContext: json['rightContext'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LSystemRule &&
        other.symbol == symbol &&
        other.replacement == replacement &&
        other.probability == probability &&
        other.isActive == isActive &&
        other.leftContext == leftContext &&
        other.rightContext == rightContext;
  }

  @override
  int get hashCode {
    return Object.hash(
      symbol,
      replacement,
      probability,
      isActive,
      leftContext,
      rightContext,
    );
  }

  @override
  String toString() {
    return 'LSystemRule(symbol: $symbol, replacement: $replacement, probability: $probability)';
  }

  /// Validates the rule properties
  List<String> validate() {
    final errors = <String>[];
    
    if (symbol.isEmpty) {
      errors.add('Rule symbol cannot be empty');
    }
    
    if (probability < 0.0 || probability > 1.0) {
      errors.add('Rule probability must be between 0.0 and 1.0');
    }
    
    if (leftContext != null && leftContext!.isEmpty) {
      errors.add('Left context cannot be empty if provided');
    }
    
    if (rightContext != null && rightContext!.isEmpty) {
      errors.add('Right context cannot be empty if provided');
    }
    
    return errors;
  }

  /// Checks if this rule is context-sensitive
  bool get isContextSensitive {
    return leftContext != null || rightContext != null;
  }

  /// Checks if this rule is stochastic
  bool get isStochastic {
    return probability < 1.0;
  }

  /// Gets the rule as a string representation
  String get ruleString {
    if (isContextSensitive) {
      final left = leftContext ?? '';
      final right = rightContext ?? '';
      return '$left<$symbol>$right -> $replacement';
    }
    return '$symbol -> $replacement';
  }

  /// Creates a simple deterministic rule
  factory LSystemRule.deterministic({
    required String symbol,
    required String replacement,
  }) {
    return LSystemRule(
      symbol: symbol,
      replacement: replacement,
      probability: 1.0,
    );
  }

  /// Creates a stochastic rule
  factory LSystemRule.stochastic({
    required String symbol,
    required String replacement,
    required double probability,
  }) {
    return LSystemRule(
      symbol: symbol,
      replacement: replacement,
      probability: probability,
    );
  }

  /// Creates a context-sensitive rule
  factory LSystemRule.contextSensitive({
    required String symbol,
    required String replacement,
    String? leftContext,
    String? rightContext,
  }) {
    return LSystemRule(
      symbol: symbol,
      replacement: replacement,
      leftContext: leftContext,
      rightContext: rightContext,
    );
  }
}
