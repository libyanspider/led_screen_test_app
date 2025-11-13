import 'package:flutter/material.dart';
import 'package:flame/game.dart';

// Models
import 'models/touch_input_event.dart';

// Input Sources
import 'input/udp_input_source.dart';
import 'input/local_input_source.dart';

// Game
import 'game/led_interactive_game.dart';

// UI
import 'ui/debug_panel.dart';
import 'ui/debug_console.dart';

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
  late UDPInputSource udpInput;
  late LocalInputSource localInput;

  bool _showDebug = true;
  bool _showDetailedDebug = false;
  List<String> _debugLog = [];

  // Stats
  int _udpPackets = 0;
  int _mouseClicks = 0;
  int _touchEvents = 0;

  // Track coordinate ranges (for UDP)
  int _minX = 999999;
  int _maxX = 0;
  int _minY = 999999;
  int _maxY = 0;

  // Input source toggles
  bool _enableUDP = true;
  bool _enableMouse = true;
  bool _enableTouch = true;

  @override
  void initState() {
    super.initState();
    game = LEDInteractiveGame();
    _initializeInputSources();
  }

  @override
  void dispose() {
    udpInput.stop();
    localInput.stop();
    super.dispose();
  }

  void _initializeInputSources() {
    // Setup UDP input with mapping
    udpInput = UDPInputSource(
      enableMapping: true,
      sensorMinX: 16.0,
      sensorMaxX: 1392.0,
      sensorMinY: 1728.0,
      sensorMaxY: 3504.0,
      targetMinX: 0.0,
      targetMaxX: 1711.0,
      targetMinY: 1684.0,
      targetMaxY: 3368.0,
    );

    udpInput.onInput = _handleInputEvent;
    udpInput.onDebugLog = _addToDebugLog;
    udpInput.onRawCoordinate = (x, y) {
      setState(() {
        if (x < _minX) _minX = x;
        if (x > _maxX) _maxX = x;
        if (y < _minY) _minY = y;
        if (y > _maxY) _maxY = y;
      });
    };

    udpInput.start();

    // Setup local input (no mapping)
    localInput = LocalInputSource();
    localInput.onInput = _handleInputEvent;
    localInput.onDebugLog = _addToDebugLog;
    localInput.start();
  }

  void _handleInputEvent(TouchInputEvent event) {
    // Check if this input source is enabled
    if (event.source == 'udp' && !_enableUDP) return;
    if (event.source == 'mouse' && !_enableMouse) return;
    if (event.source == 'touch' && !_enableTouch) return;

    // Update stats
    setState(() {
      switch (event.source) {
        case 'udp':
          _udpPackets++;
          break;
        case 'mouse':
          _mouseClicks++;
          break;
        case 'touch':
          _touchEvents++;
          break;
      }
    });

    // Send to game
    game.addTouchEffect(event.x, event.y, source: event.source);
  }

  void _addToDebugLog(String message) {
    setState(() {
      _debugLog.add('${DateTime.now().toString().substring(11, 23)}: $message');
      if (_debugLog.length > 50) {
        _debugLog.removeAt(0);
      }
    });
  }

  /// Convert screen coordinates to virtual coordinates
  Offset _screenToVirtualCoords(double screenX, double screenY) {
    // Check if game has layout before accessing size
    if (game.scaleToFit && game.hasLayout) {
      // Convert from screen space back to virtual space
      final virtualX = screenX / game.size.x * LEDInteractiveGame.virtualWidth;
      final virtualY = screenY / game.size.y * LEDInteractiveGame.virtualHeight;
      return Offset(virtualX, virtualY);
    }
    return Offset(screenX, screenY);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Game canvas with gesture detection
          GestureDetector(
            onTapDown: (details) {
              if (_enableMouse) {
                final coords = _screenToVirtualCoords(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
                localInput.handleLocalInput(
                  coords.dx,
                  coords.dy,
                  'mouse',
                );
              }
            },
            onPanUpdate: (details) {
              if (_enableTouch) {
                final coords = _screenToVirtualCoords(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
                localInput.handleLocalInput(
                  coords.dx,
                  coords.dy,
                  'touch',
                );
              }
            },
            child: GameWidget(game: game),
          ),

          // Debug overlay
          if (_showDebug)
            Positioned(
              top: 20,
              left: 20,
              child: DebugPanel(
                isUDPActive: udpInput.isActive,
                udpPackets: _udpPackets,
                mouseClicks: _mouseClicks,
                touchEvents: _touchEvents,
                windowSize: size,
                fps: game.fps,
                activeScreen: game.activeScreen,
                onScreenChanged: (screen) {
                  setState(() {
                    game.setActiveScreen(screen);
                  });
                },
                showSeparator: game.showSeparator,
                onSeparatorToggle: (show) {
                  setState(() {
                    game.toggleSeparator(show);
                  });
                },
                scaleToFit: game.scaleToFit,
                onScaleToggle: (scale) {
                  setState(() {
                    game.toggleScaleToFit(scale);
                  });
                },
                scalingInfo: game.getScalingInfo(),
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
              child: DebugConsole(
                debugLog: _debugLog,
                onClear: () => setState(() => _debugLog.clear()),
                onCopy: () {
                  final log = _debugLog.join('\n');
                  print('Debug log:\n$log');
                },
                windowSize: size,
                minX: _minX,
                maxX: _maxX,
                minY: _minY,
                maxY: _maxY,
                onResetMinMax: () => setState(() {
                  _minX = 999999;
                  _maxX = 0;
                  _minY = 999999;
                  _maxY = 0;
                }),
                enableUDP: _enableUDP,
                enableMouse: _enableMouse,
                enableTouch: _enableTouch,
                onUDPToggle: (val) => setState(() => _enableUDP = val),
                onMouseToggle: (val) => setState(() => _enableMouse = val),
                onTouchToggle: (val) => setState(() => _enableTouch = val),
                udpInput: udpInput,
                onMappingToggle: (val) =>
                    setState(() => udpInput.enableMapping = val),
              ),
            ),
        ],
      ),
    );
  }
}
