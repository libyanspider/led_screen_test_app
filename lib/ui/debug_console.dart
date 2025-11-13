import 'package:flutter/material.dart';
import '../input/udp_input_source.dart';

/// Detailed debug console with logs and configuration
class DebugConsole extends StatelessWidget {
  final List<String> debugLog;
  final VoidCallback onClear;
  final VoidCallback onCopy;
  final Size windowSize;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final VoidCallback onResetMinMax;
  final bool enableUDP;
  final bool enableMouse;
  final bool enableTouch;
  final ValueChanged<bool> onUDPToggle;
  final ValueChanged<bool> onMouseToggle;
  final ValueChanged<bool> onTouchToggle;
  final UDPInputSource udpInput;
  final ValueChanged<bool> onMappingToggle;

  const DebugConsole({
    super.key,
    required this.debugLog,
    required this.onClear,
    required this.onCopy,
    required this.windowSize,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.onResetMinMax,
    required this.enableUDP,
    required this.enableMouse,
    required this.enableTouch,
    required this.onUDPToggle,
    required this.onMouseToggle,
    required this.onTouchToggle,
    required this.udpInput,
    required this.onMappingToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max height based on screen size
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                onPressed: onCopy,
                tooltip: 'Copy to clipboard (check console)',
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                onPressed: onClear,
                tooltip: 'Clear log',
              ),
            ],
          ),
          const Divider(color: Colors.purple),
          
          // Window and sensor info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Window Size: ${windowSize.width.toInt()}x${windowSize.height.toInt()}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sensor Ranges (All-Time):',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      minX == 999999 
                          ? '  X: No data yet'
                          : '  X: $minX to $maxX (range: ${maxX - minX})',
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      minY == 999999
                          ? '  Y: No data yet'
                          : '  Y: $minY to $maxY (range: ${maxY - minY})',
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: onResetMinMax,
                tooltip: 'Reset min/max values',
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Input source toggles - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Input Sources',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: enableUDP,
                        onChanged: (val) => onUDPToggle(val ?? true),
                        activeColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Text('UDP', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(width: 12),
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: enableMouse,
                        onChanged: (val) => onMouseToggle(val ?? true),
                        activeColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Text('Mouse', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(width: 12),
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: enableTouch,
                        onChanged: (val) => onTouchToggle(val ?? true),
                        activeColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Text('Touch', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // UDP Mapping configuration - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purple.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'UDP Mapping',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      udpInput.enableMapping ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: udpInput.enableMapping ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: udpInput.enableMapping,
                        onChanged: onMappingToggle,
                        activeColor: Colors.purple,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                if (udpInput.enableMapping) ...[
                  Text(
                    'Sensor: X[${udpInput.sensorMinX.toInt()}-${udpInput.sensorMaxX.toInt()}] Y[${udpInput.sensorMinY.toInt()}-${udpInput.sensorMaxY.toInt()}]',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                  Text(
                    'Target: X[${udpInput.targetMinX.toInt()}-${udpInput.targetMaxX.toInt()}] Y[${udpInput.targetMinY.toInt()}-${udpInput.targetMaxY.toInt()}]',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.purple, height: 8),
          
          // Log
          const Text(
            'Recent Packets:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: debugLog.length,
                itemBuilder: (context, index) {
                  final logIndex = debugLog.length - 1 - index;
                  final log = debugLog[logIndex];
                  Color textColor = Colors.white70;
                  
                  if (log.contains('ERROR')) {
                    textColor = Colors.red;
                  } else if (log.contains('Point')) {
                    textColor = Colors.cyan;
                  } else if (log.contains('Packet #') || log.contains('UDP:') || log.contains('mouse:') || log.contains('touch:')) {
                    textColor = Colors.green;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 9,
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
    );
  }
}
