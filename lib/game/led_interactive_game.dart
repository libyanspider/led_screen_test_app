import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'components/ripple_effect.dart';
import 'components/particle_burst.dart';
import 'components/touch_marker.dart';
import 'components/screen_separator.dart';

enum ScreenArea { top, bottom, both }

/// Main Flame game for LED interactive effects
class LEDInteractiveGame extends FlameGame {
  double fps = 0;
  int _frameCount = 0;
  double _elapsed = 0;
  
  // Screen separation
  bool showSeparator = true;
  ScreenArea activeScreen = ScreenArea.bottom;
  ScreenSeparator? _separator;
  
  // Screen dimensions (from UDP target ranges)
  static const double topScreenHeight = 1684.0;
  static const double bottomScreenYStart = 1684.0;
  static const double bottomScreenHeight = 1684.0;
  
  // Virtual screen dimensions (full dual-screen setup)
  static const double virtualWidth = 1711.0;
  static const double virtualHeight = 3368.0; // 1684 + 1684
  
  // Scaling
  bool scaleToFit = true;
  double _scaleX = 1.0;
  double _scaleY = 1.0;

  @override
  Color backgroundColor() => const Color(0xFF000510);

  @override
  void onLoad() {
    super.onLoad();
    _updateScaling();
    _updateSeparator();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateScaling();
    _updateSeparator();
  }

  void _updateScaling() {
    // Only update scaling if game has layout
    if (!hasLayout) {
      _scaleX = 1.0;
      _scaleY = 1.0;
      return;
    }
    
    if (scaleToFit && size.x > 0 && size.y > 0) {
      _scaleX = size.x / virtualWidth;
      _scaleY = size.y / virtualHeight;
    } else {
      _scaleX = 1.0;
      _scaleY = 1.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Calculate FPS
    _frameCount++;
    _elapsed += dt;
    if (_elapsed >= 1.0) {
      fps = _frameCount / _elapsed;
      _frameCount = 0;
      _elapsed = 0;
    }
  }

  void _updateSeparator() {
    // Remove old separator if exists
    if (_separator != null) {
      _separator!.removeFromParent();
      _separator = null;
    }

    // Add new separator if enabled and game has layout
    if (showSeparator && hasLayout) {
      final separatorY = scaleToFit ? bottomScreenYStart * _scaleY : bottomScreenYStart;
      _separator = ScreenSeparator(
        separatorY: separatorY,
        screenWidth: size.x,
      );
      add(_separator!);
    }
  }

  void toggleSeparator(bool show) {
    showSeparator = show;
    _updateSeparator();
  }

  void setActiveScreen(ScreenArea screen) {
    activeScreen = screen;
  }

  void toggleScaleToFit(bool scale) {
    scaleToFit = scale;
    _updateScaling();
    _updateSeparator();
  }

  /// Transform coordinates from virtual space to actual screen space
  Vector2 _transformCoordinates(double x, double y) {
    if (scaleToFit) {
      return Vector2(x * _scaleX, y * _scaleY);
    }
    return Vector2(x, y);
  }

  /// Add visual effects at the specified coordinates
  void addTouchEffect(double x, double y, {String source = 'unknown'}) {
    // Check if coordinate is in the active screen area (in virtual space)
    if (!_isInActiveScreen(y)) {
      return; // Don't render if not in active screen
    }

    // Transform coordinates to screen space
    final transformed = _transformCoordinates(x, y);

    // Choose color based on source
    Color color = Colors.cyan;
    switch (source) {
      case 'udp':
        color = Colors.cyan;
        break;
      case 'mouse':
        color = Colors.orange;
        break;
      case 'touch':
        color = Colors.pink;
        break;
    }
    
    // Add ripple effect
    add(RippleEffect(position: transformed, color: color));

    // Add particle burst
    add(ParticleBurst(position: transformed, color: color));

    // Add touch marker
    add(TouchMarker(position: transformed, color: color));
  }

  bool _isInActiveScreen(double y) {
    switch (activeScreen) {
      case ScreenArea.top:
        return y < bottomScreenYStart;
      case ScreenArea.bottom:
        return y >= bottomScreenYStart;
      case ScreenArea.both:
        return true;
    }
  }

  String getScalingInfo() {
    // Check if game has layout before accessing size
    if (!hasLayout) {
      return 'Initializing...';
    }
    
    if (scaleToFit) {
      return 'Virtual: ${virtualWidth.toInt()}x${virtualHeight.toInt()} → Screen: ${size.x.toInt()}x${size.y.toInt()} (${(_scaleX * 100).toStringAsFixed(1)}%)';
    }
    return '1:1 (No scaling)';
  }
}
