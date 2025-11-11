import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Interactive Screen - Flame',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
      ),
      home: const LEDInteractiveGameScreen(),
    );
  }
}

class LEDInteractiveGameScreen extends StatefulWidget {
  const LEDInteractiveGameScreen({super.key});

  @override
  State<LEDInteractiveGameScreen> createState() =>
      _LEDInteractiveGameScreenState();
}

class _LEDInteractiveGameScreenState extends State<LEDInteractiveGameScreen> {
  late LEDInteractiveGame game;
  RawDatagramSocket? _socket;
  bool _isListening = false;
  String _statusMessage = 'Not connected';
  int _packetsReceived = 0;
  bool _showDebug = true;

  @override
  void initState() {
    super.initState();
    game = LEDInteractiveGame();
    _startListening();
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 25000);

      setState(() {
        _isListening = true;
        _statusMessage = 'Listening on port 25000';
      });

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _socket!.receive();
          if (datagram != null) {
            _processData(datagram.data);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isListening = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _processData(Uint8List data) {
    try {
      setState(() {
        _packetsReceived++;
      });

      if (data.length < 6) return;

      int numPoints = data[4] | (data[5] << 8);
      int expectedLength = 6 + (numPoints * 4);
      if (data.length < expectedLength) return;

      for (int i = 0; i < numPoints; i++) {
        int offset = 6 + (i * 4);
        int x = data[offset] | (data[offset + 1] << 8);
        int y = data[offset + 2] | (data[offset + 3] << 8);

        // Add touch effect to the game
        game.addTouchEffect(x.toDouble(), y.toDouble());
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Parse error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas
          GameWidget(game: game),

          // Debug overlay
          if (_showDebug)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isListening ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: _isListening ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Packets: $_packetsReceived',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'FPS: ${game.fps.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // Toggle debug button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: () => setState(() => _showDebug = !_showDebug),
              child: Icon(_showDebug ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ],
      ),
    );
  }
}

// Flame Game
class LEDInteractiveGame extends FlameGame {
  double fps = 0;
  int _frameCount = 0;
  double _elapsed = 0;

  @override
  Color backgroundColor() => const Color(0xFF000510);

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

  void addTouchEffect(double x, double y) {
    // Add ripple effect
    add(RippleEffect(position: Vector2(x, y)));

    // Add particle burst
    add(ParticleBurst(position: Vector2(x, y)));

    // Add touch marker
    add(TouchMarker(position: Vector2(x, y)));
  }
}

// Ripple Effect Component
class RippleEffect extends PositionComponent with HasPaint {
  double _opacity = 1.0;
  double _elapsed = 0.0;
  static const double _lifetime = 1.0;

  RippleEffect({required Vector2 position})
      : super(position: position, size: Vector2.all(0), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Expand effect
    add(
      ScaleEffect.to(
        Vector2.all(100),
        EffectController(duration: _lifetime, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _opacity = 1.0 - (_elapsed / _lifetime);

    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.6 * _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}

// Particle Burst Effect
class ParticleBurst extends PositionComponent {
  ParticleBurst({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Create multiple particles
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      add(Particle(
        startAngle: angle,
        onComplete: () => removeFromParent(),
      ));
    }

    // Remove parent after particles are done
    Future.delayed(const Duration(milliseconds: 800), () {
      if (isMounted) removeFromParent();
    });
  }
}

// Individual Particle
class Particle extends PositionComponent {
  final double startAngle;
  final VoidCallback onComplete;
  static const double speed = 150.0;
  static const double lifetime = 0.8;
  double elapsed = 0;

  Particle({required this.startAngle, required this.onComplete})
      : super(size: Vector2.all(6), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    elapsed += dt;
    if (elapsed >= lifetime) {
      removeFromParent();
      return;
    }

    // Move outward
    position.x += speed * dt * (1 - elapsed / lifetime) * cos(startAngle);
    position.y += speed * dt * (1 - elapsed / lifetime) * sin(startAngle);
  }

  @override
  void render(Canvas canvas) {
    final opacity = 1 - (elapsed / lifetime);
    final paint = Paint()
      ..color = Colors.blue.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}

// Touch Marker (stays briefly)
class TouchMarker extends PositionComponent with HasPaint {
  double _opacity = 1.0;
  double _elapsed = 0.0;
  static const double _pulseDuration = 0.3;
  static const double _fadeStart = 0.2;
  static const double _lifetime = 0.8;
  double _scale = 1.0;

  TouchMarker({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(30),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Pulse effect
    if (_elapsed < _pulseDuration * 2) {
      final progress = _elapsed / _pulseDuration;
      if (progress < 1.0) {
        _scale = 1.0 + 0.5 * progress;
      } else {
        _scale = 1.5 - 0.5 * (progress - 1.0);
      }
    }

    // Fade out
    if (_elapsed >= _fadeStart) {
      _opacity = 1.0 - ((_elapsed - _fadeStart) / (_lifetime - _fadeStart));
    }

    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(_scale);

    // Outer glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, size.x / 2, glowPaint);

    // Inner circle
    final paint = Paint()
      ..color = Colors.white.withOpacity(_opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 3, paint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.cyan.withOpacity(_opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, size.x / 2, ringPaint);

    canvas.restore();
  }
}
