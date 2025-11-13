/// Model representing a touch/click input event from any source
class TouchInputEvent {
  final double x;
  final double y;
  final String source; // 'udp', 'mouse', 'touch'
  final DateTime timestamp;
  
  TouchInputEvent({
    required this.x,
    required this.y,
    required this.source,
  }) : timestamp = DateTime.now();
}
