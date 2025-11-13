import 'package:flutter/material.dart';
import '../game/led_interactive_game.dart';

/// Basic debug information panel shown in top-left corner
class DebugPanel extends StatelessWidget {
  final bool isUDPActive;
  final int udpPackets;
  final int mouseClicks;
  final int touchEvents;
  final Size windowSize;
  final double fps;
  final ScreenArea activeScreen;
  final ValueChanged<ScreenArea> onScreenChanged;
  final bool showSeparator;
  final ValueChanged<bool> onSeparatorToggle;
  final bool scaleToFit;
  final ValueChanged<bool> onScaleToggle;
  final String scalingInfo;

  const DebugPanel({
    super.key,
    required this.isUDPActive,
    required this.udpPackets,
    required this.mouseClicks,
    required this.touchEvents,
    required this.windowSize,
    required this.fps,
    required this.activeScreen,
    required this.onScreenChanged,
    required this.showSeparator,
    required this.onSeparatorToggle,
    required this.scaleToFit,
    required this.onScaleToggle,
    required this.scalingInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUDPActive ? Colors.green : Colors.red,
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
                color: isUDPActive ? Colors.green : Colors.red,
                size: 12,
              ),
              const SizedBox(width: 8),
              const Text(
                'Multi-Input Active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'UDP: $udpPackets | Mouse: $mouseClicks | Touch: $touchEvents',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'Window: ${windowSize.width.toInt()}x${windowSize.height.toInt()}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'FPS: ${fps.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const Divider(color: Colors.white30, height: 16),
          
          // Screen selector
          const Text(
            'Target Screen:',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: DropdownButton<ScreenArea>(
              value: activeScreen,
              dropdownColor: Colors.black87,
              underline: Container(),
              isDense: true,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              items: const [
                DropdownMenuItem(
                  value: ScreenArea.top,
                  child: Text('🔼 Top Screen'),
                ),
                DropdownMenuItem(
                  value: ScreenArea.bottom,
                  child: Text('🔽 Bottom Screen (Touch)'),
                ),
                DropdownMenuItem(
                  value: ScreenArea.both,
                  child: Text('🔄 Both Screens'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onScreenChanged(value);
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Separator toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: showSeparator,
                onChanged: (val) => onSeparatorToggle(val ?? true),
                activeColor: Colors.amber,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Show Screen Separator',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Scale to fit toggle
          const Divider(color: Colors.white30, height: 12),
          const Text(
            'Display Mode:',
            style: TextStyle(
              color: Colors.lightBlue,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: scaleToFit,
                onChanged: (val) => onScaleToggle(val ?? true),
                activeColor: Colors.lightBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Scale to Fit Window',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
            ),
            child: Text(
              scalingInfo,
              style: const TextStyle(
                color: Colors.lightBlue,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
