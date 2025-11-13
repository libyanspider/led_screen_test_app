import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle.dart';

/// Particle burst effect with multiple particles shooting outward
class ParticleBurst extends PositionComponent {
  final Color color;
  
  ParticleBurst({required Vector2 position, this.color = Colors.cyan})
      : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Create multiple particles
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      add(Particle(
        startAngle: angle,
        color: color,
        onComplete: () => removeFromParent(),
      ));
    }

    // Remove parent after particles are done
    Future.delayed(const Duration(milliseconds: 800), () {
      if (isMounted) removeFromParent();
    });
  }
}
