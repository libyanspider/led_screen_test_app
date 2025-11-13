import 'input_source.dart';
import '../models/touch_input_event.dart';

/// Local Input Source for mouse clicks and touch events
class LocalInputSource implements InputSource {
  @override
  void Function(TouchInputEvent)? onInput;
  
  void Function(String)? onDebugLog;
  
  @override
  void start() {
    // Local input is always active, managed by Flutter gestures
  }
  
  @override
  void stop() {
    // Nothing to stop for local input
  }
  
  /// Handle local input from mouse or touch
  void handleLocalInput(double x, double y, String type) {
    onDebugLog?.call('$type: ($x, $y) [Direct]');
    onInput?.call(TouchInputEvent(
      x: x,
      y: y,
      source: type,
    ));
  }
}
