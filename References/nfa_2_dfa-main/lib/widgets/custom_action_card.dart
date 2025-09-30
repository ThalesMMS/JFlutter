import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CardAnimationType { scale, rotate, flip, slide, glow }

enum CardSize { small, medium, large }

class AdvancedCustomActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final CardAnimationType animationType;
  final CardSize cardSize;
  final bool enableRipple;
  final bool enableParallax;
  final double elevation;
  final Color? borderColor;
  final double borderWidth;
  final Widget? badge;
  final bool isEnabled;
  final Duration animationDuration;
  final List<BoxShadow>? customShadows;
  final Widget? backgroundPattern;
  final double iconRotation;
  final bool enablePulse;
  final Color? overlayColor;

  const AdvancedCustomActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.onLongPress,
    this.animationType = CardAnimationType.scale,
    this.cardSize = CardSize.medium,
    this.enableRipple = true,
    this.enableParallax = false,
    this.elevation = 8.0,
    this.borderColor,
    this.borderWidth = 0.0,
    this.badge,
    this.isEnabled = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.customShadows,
    this.backgroundPattern,
    this.iconRotation = 0.0,
    this.enablePulse = false,
    this.overlayColor,
  });

  @override
  State<AdvancedCustomActionCard> createState() =>
      _AdvancedCustomActionCardState();
}

class _AdvancedCustomActionCardState extends State<AdvancedCustomActionCard>
    with TickerProviderStateMixin {
  late final AnimationController _primaryController;
  late final AnimationController _pulseController;
  late final AnimationController _parallaxController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _flipAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<Offset> _parallaxAnimation;

  bool _isHovering = false;
  bool _isPressed = false;
  Offset _localPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _initializeAnimations() {
    _primaryController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Scale Animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: _getScaleEnd()).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.elasticOut),
    );

    // Rotate Animation
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
    );

    // Flip Animation
    _flipAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
    );

    // Slide Animation
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.1)).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeOut),
        );

    // Glow Animation
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
    );

    // Pulse Animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Parallax Animation
    _parallaxAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_parallaxController);
  }

  double _getScaleEnd() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 1.03;
      case CardSize.medium:
        return 1.05;
      case CardSize.large:
        return 1.08;
    }
  }

  Size _getCardSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return const Size(120, 140);
      case CardSize.medium:
        return const Size(160, 180);
      case CardSize.large:
        return const Size(200, 220);
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _pulseController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (!widget.isEnabled) return;

    setState(() {
      _isHovering = isHovering;
      if (_isHovering) {
        _primaryController.forward();
      } else {
        _primaryController.reverse();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableParallax || !widget.isEnabled) return;

    setState(() {
      _localPosition = details.localPosition;
      final size = _getCardSize();
      final center = Offset(size.width / 2, size.height / 2);
      final offset = (_localPosition - center) / 100;

      _parallaxAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: offset,
      ).animate(_parallaxController);

      _parallaxController.forward();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableParallax) return;
    _parallaxController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onTapCancel() {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
  }

  Widget _buildAnimatedCard(Widget child) {
    switch (widget.animationType) {
      case CardAnimationType.scale:
        return ScaleTransition(scale: _scaleAnimation, child: child);
      case CardAnimationType.rotate:
        return AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) =>
              Transform.rotate(angle: _rotateAnimation.value, child: child),
          child: child,
        );
      case CardAnimationType.flip:
        return AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_flipAnimation.value),
            child: child,
          ),
          child: child,
        );
      case CardAnimationType.slide:
        return SlideTransition(position: _slideAnimation, child: child);
      case CardAnimationType.glow:
        return child;
    }
  }

  List<BoxShadow> _buildShadows() {
    if (widget.customShadows != null) return widget.customShadows!;

    final colors = (widget.gradient as LinearGradient).colors;
    final primaryColor = colors.first;

    double intensity = widget.animationType == CardAnimationType.glow
        ? _glowAnimation.value
        : (_isHovering ? 0.5 : 0.3);

    if (widget.enablePulse) {
      intensity *= _pulseAnimation.value;
    }

    return [
      BoxShadow(
        color: primaryColor.withOpacity(intensity),
        blurRadius: _isHovering ? 25 : 15,
        spreadRadius: _isHovering ? 2 : 0,
        offset: Offset(0, widget.elevation),
      ),
      if (_isPressed)
        BoxShadow(
          color: primaryColor.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = _getCardSize();

    Widget card = MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          width: cardSize.width,
          height: cardSize.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: _buildShadows(),
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Pattern
                if (widget.backgroundPattern != null)
                  Positioned.fill(child: widget.backgroundPattern!),

                // Main Content
                Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(gradient: widget.gradient),
                    child: widget.enableParallax
                        ? AnimatedBuilder(
                            animation: _parallaxAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: _parallaxAnimation.value,
                              child: _buildCardContent(),
                            ),
                          )
                        : _buildCardContent(),
                  ),
                ),

                // Overlay
                if (widget.overlayColor != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.overlayColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                // Ripple Effect
                if (widget.enableRipple)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isEnabled ? widget.onTap : null,
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                // Badge
                if (widget.badge != null)
                  Positioned(top: 8, right: 8, child: widget.badge!),

                // Disabled Overlay
                if (!widget.isEnabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply pulse animation if enabled
    if (widget.enablePulse) {
      card = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _pulseAnimation.value, child: child),
        child: card,
      );
    }

    return _buildAnimatedCard(card);
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Transform.rotate(
            angle: widget.iconRotation,
            child: Icon(
              widget.icon,
              size: _getIconSize(),
              color: widget.isEnabled ? Colors.white : Colors.white70,
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          SizedBox(height: _getSpacing()),

          // Title
          Text(
            widget.title,
            style: TextStyle(
              color: widget.isEnabled ? Colors.white : Colors.white70,
              fontSize: _getTitleSize(),
              fontWeight: FontWeight.bold,
              shadows: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getSpacing() / 2),

          // Subtitle
          Text(
            widget.subtitle,
            style: TextStyle(
              color: widget.isEnabled
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.6),
              fontSize: _getSubtitleSize(),
              shadows: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _getIconSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 28;
      case CardSize.medium:
        return 36;
      case CardSize.large:
        return 44;
    }
  }

  double _getTitleSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 14;
      case CardSize.medium:
        return 17;
      case CardSize.large:
        return 20;
    }
  }

  double _getSubtitleSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 11;
      case CardSize.medium:
        return 13;
      case CardSize.large:
        return 15;
    }
  }

  double _getSpacing() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 12;
      case CardSize.medium:
        return 16;
      case CardSize.large:
        return 20;
    }
  }
}
