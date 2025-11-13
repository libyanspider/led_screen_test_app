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
  bool _showDetailedDebug = false;
  List<String> _debugLog = [];
  String _lastRawHex = '';
  String _lastParsedInfo = '';

  // Track coordinate ranges
  int _minX = 999999;
  int _maxX = 0;
  int _minY = 999999;
  int _maxY = 0;

  // Coordinate mapping configuration
  bool _enableMapping = true;
  double _sensorMinX = 16.0;
  double _sensorMaxX = 1392.0;
  double _sensorMinY = 1728.0;
  double _sensorMaxY = 3504.0;
  double _targetMinX = 0.0;
  double _targetMaxX = 1711.0;
  double _targetMinY = 1684.0; // Bottom screen starts here (half of 3368)
  double _targetMaxY = 3368.0; // Bottom of combined display

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

        // Update raw hex display
        _lastRawHex = data
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(' ');

        // Add to debug log
        _addToDebugLog('Packet #$_packetsReceived: ${data.length} bytes');
        _addToDebugLog('Raw: $_lastRawHex');
      });

      if (data.length < 6) {
        _addToDebugLog(
            'ERROR: Packet too short (${data.length} bytes, need at least 6)');
        setState(() {
          _lastParsedInfo = 'ERROR: Packet too short';
        });
        return;
      }

      // Parse header
      int frameNum = data[0] | (data[1] << 8);
      int ignore1 = data[2] | (data[3] << 8);
      int numPoints = data[4] | (data[5] << 8);
      int expectedLength = 6 + (numPoints * 4);

      setState(() {
        _lastParsedInfo =
            'Frame: $frameNum, Points: $numPoints, Length: ${data.length}/$expectedLength';
      });
      _addToDebugLog(
          'Frame: 0x${frameNum.toRadixString(16)}, Ignore: 0x${ignore1.toRadixString(16)}, Points: $numPoints');

      if (data.length < expectedLength) {
        _addToDebugLog(
            'ERROR: Not enough data for $numPoints points (have ${data.length}, need $expectedLength)');
        return;
      }

      // Parse and add touch points
      for (int i = 0; i < numPoints; i++) {
        int offset = 6 + (i * 4);
        int x = data[offset] | (data[offset + 1] << 8);
        int y = data[offset + 2] | (data[offset + 3] << 8);

        // Track min/max coordinates
        if (x < _minX) _minX = x;
        if (x > _maxX) _maxX = x;
        if (y < _minY) _minY = y;
        if (y > _maxY) _maxY = y;

        // Map coordinates if enabled
        double mappedX = x.toDouble();
        double mappedY = y.toDouble();

        if (_enableMapping) {
          // Linear mapping: sensor range -> target range
          mappedX = _targetMinX +
              ((x - _sensorMinX) / (_sensorMaxX - _sensorMinX)) *
                  (_targetMaxX - _targetMinX);

          mappedY = _targetMinY +
              ((y - _sensorMinY) / (_sensorMaxY - _sensorMinY)) *
                  (_targetMaxY - _targetMinY);
        }

        _addToDebugLog(
            'Point $i: Raw X=$x, Y=$y -> Mapped X=${mappedX.toInt()}, Y=${mappedY.toInt()}');
        _addToDebugLog(
            '  Hex: X=(0x${data[offset].toRadixString(16)} 0x${data[offset + 1].toRadixString(16)}), Y=(0x${data[offset + 2].toRadixString(16)} 0x${data[offset + 3].toRadixString(16)})');

        // Add touch effect to the game with mapped coordinates
        game.addTouchEffect(mappedX, mappedY);
      }

      _addToDebugLog('---');
    } catch (e) {
      setState(() {
        _statusMessage = 'Parse error: $e';
      });
      _addToDebugLog('EXCEPTION: $e');
    }
  }

  void _addToDebugLog(String message) {
    setState(() {
      _debugLog.add('${DateTime.now().toString().substring(11, 23)}: $message');
      if (_debugLog.length > 50) {
        _debugLog.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Window: ${size.width.toInt()}x${size.height.toInt()}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'FPS: ${game.fps.toStringAsFixed(0)}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Toggle debug buttons
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () => setState(() => _showDebug = !_showDebug),
                  tooltip: 'Toggle basic debug',
                  child: Icon(
                      _showDebug ? Icons.visibility_off : Icons.visibility),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () =>
                      setState(() => _showDetailedDebug = !_showDetailedDebug),
                  tooltip: 'Toggle detailed debug',
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.bug_report),
                ),
              ],
            ),
          ),

          // Detailed Debug Console
          if (_showDetailedDebug)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 400,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'DEBUG CONSOLE',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            // Copy debug log to clipboard
                            final log = _debugLog.join('\n');
                            // You can implement clipboard copy here if needed
                            print('Debug log:\n$log');
                          },
                          tooltip: 'Copy to clipboard (check console)',
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            setState(() {
                              _debugLog.clear();
                            });
                          },
                          tooltip: 'Clear log',
                        ),
                      ],
                    ),
                    const Divider(color: Colors.purple),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Window Size: ${size.width.toInt()}x${size.height.toInt()}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinate Ranges (All-Time):',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _minX == 999999
                                    ? '  X: No data yet'
                                    : '  X: $_minX to $_maxX (range: ${_maxX - _minX})',
                                style: const TextStyle(
                                  color: Colors.lightBlue,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _minY == 999999
                                    ? '  Y: No data yet'
                                    : '  Y: $_minY to $_maxY (range: ${_maxY - _minY})',
                                style: const TextStyle(
                                  color: Colors.lightBlue,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            setState(() {
                              _minX = 999999;
                              _maxX = 0;
                              _minY = 999999;
                              _maxY = 0;
                            });
                          },
                          tooltip: 'Reset min/max values',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Coordinate mapping section
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Coordinate Mapping',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _enableMapping ? 'ON' : 'OFF',
                                style: TextStyle(
                                  color: _enableMapping
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _enableMapping,
                                onChanged: (val) =>
                                    setState(() => _enableMapping = val),
                                activeColor: Colors.purple,
                              ),
                            ],
                          ),
                          if (_enableMapping) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Sensor: X[${_sensorMinX.toInt()}-${_sensorMaxX.toInt()}] Y[${_sensorMinY.toInt()}-${_sensorMaxY.toInt()}]',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9),
                            ),
                            Text(
                              'Target: X[${_targetMinX.toInt()}-${_targetMaxX.toInt()}] Y[${_targetMinY.toInt()}-${_targetMaxY.toInt()}]',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bottom screen projection enabled',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Raw (Hex): $_lastRawHex',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parsed: $_lastParsedInfo',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                      ),
                    ),
                    const Divider(color: Colors.purple),
                    const Text(
                      'Recent Packets:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          reverse: true,
                          itemCount: _debugLog.length,
                          itemBuilder: (context, index) {
                            final logIndex = _debugLog.length - 1 - index;
                            final log = _debugLog[logIndex];
                            Color textColor = Colors.white70;

                            if (log.contains('ERROR')) {
                              textColor = Colors.red;
                            } else if (log.contains('Point')) {
                              textColor = Colors.cyan;
                            } else if (log.contains('Packet #')) {
                              textColor = Colors.green;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
