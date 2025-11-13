import '../models/touch_input_event.dart';

/// Abstract base class for all input sources
abstract class InputSource {
  /// Callback triggered when input is received
  void Function(TouchInputEvent)? onInput;
  
  /// Start listening for input
  void start();
  
  /// Stop listening and clean up resources
  void stop();
}
