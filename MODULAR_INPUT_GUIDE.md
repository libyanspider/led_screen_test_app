# Modular Input System Guide

## 🎯 Overview

The app now features a **modular input architecture** that supports multiple input sources simultaneously, each with configurable behavior.

## 📐 Architecture

### Input Event Model
```dart
class TouchInputEvent {
  final double x;           // Processed X coordinate
  final double y;           // Processed Y coordinate
  final String source;      // 'udp', 'mouse', or 'touch'
  final DateTime timestamp;
}
```

### Input Sources

#### 1. **UDPInputSource** (with coordinate mapping)
- Listens on UDP port 25000
- Parses LED Interactive protocol
- **Supports coordinate mapping** from sensor space to screen space
- Pre-configured for your dual-screen setup:
  - Sensor range: X[16-1392], Y[1728-3504]
  - Target range: X[0-1711], Y[1684-3368] (bottom screen)

#### 2. **LocalInputSource** (direct coordinates)
- Mouse clicks: Single tap detection
- Touch/Drag: Continuous touch tracking
- **No coordinate mapping** - uses raw window coordinates

## 🎨 Visual Feedback by Source

Each input source has its own color for easy identification:

- 🔵 **UDP**: Cyan effects
- 🟠 **Mouse**: Orange effects  
- 🟣 **Touch**: Pink effects

## 🎮 Controls

### Basic Debug Panel (Top-Left)
- **Status indicator**: Green when UDP is active
- **Stats**: `UDP: X | Mouse: Y | Touch: Z`
- **Window size**: Current window dimensions
- **FPS counter**: Performance metric

### Input Source Toggles (Debug Console)
Enable/disable each input source independently:
- ☑️ UDP (with mapping)
- ☑️ Mouse Clicks (direct)
- ☑️ Touch/Drag (direct)

### UDP Mapping Controls (Debug Console)
- **Toggle switch**: Enable/disable coordinate mapping for UDP
- **Sensor ranges**: Displays current sensor coordinate space
- **Target ranges**: Displays target window coordinate space
- **Auto-update**: Mapping applies only to UDP input

## 🔧 How It Works

### UDP Input Flow
```
UDP Packet → Parse Protocol → Track Min/Max → Apply Mapping (if enabled) → TouchInputEvent → Game Effect
```

### Local Input Flow
```
Mouse/Touch Event → Get Window Coordinates → TouchInputEvent → Game Effect
```

## 💡 Usage Examples

### Test All Input Sources

1. **UDP Input**: 
   ```bash
   python3 quick_test.py
   ```
   See cyan effects at mapped coordinates

2. **Mouse Input**: 
   Click anywhere on the window
   See orange effects at click position

3. **Touch Input**: 
   Drag your finger (or mouse) across the window
   See continuous pink effects

### Configure UDP Mapping

The UDP mapping is pre-configured for your setup, but you can adjust:

```dart
udpInput = UDPInputSource(
  enableMapping: true,
  // Sensor coordinates (from LED screen)
  sensorMinX: 16.0,
  sensorMaxX: 1392.0,
  sensorMinY: 1728.0,
  sensorMaxY: 3504.0,
  // Target coordinates (window space)
  targetMinX: 0.0,
  targetMaxX: 1711.0,
  targetMinY: 1684.0,   // Bottom screen starts here
  targetMaxY: 3368.0,    // Full window height
);
```

### Disable Specific Inputs

In the debug console, uncheck any input source to disable it:
- Uncheck UDP → No more sensor input
- Uncheck Mouse → Clicks won't create effects  
- Uncheck Touch → Dragging won't create effects

## 🎯 Key Benefits

1. **Modularity**: Easy to add new input sources
2. **Flexibility**: Each source can have its own processing logic
3. **Visual Clarity**: Color-coded effects identify the source
4. **Independent Control**: Enable/disable sources without code changes
5. **Clean Separation**: UDP mapping doesn't affect local input

## 🔍 Debug Information

The debug console shows detailed logs for all inputs:

```
14:23:45.123: UDP: Raw(700, 2500) -> Mapped(855, 2592)
14:23:45.456: mouse: (450, 300) [Direct]
14:23:45.789: touch: (600, 800) [Direct]
```

- **UDP logs**: Show both raw sensor coordinates and mapped window coordinates
- **Local logs**: Show direct window coordinates with [Direct] tag

## 📊 Stats Tracking

The app tracks separate counters for each input source:
- UDP packets received
- Mouse clicks counted
- Touch events logged

All visible in the top-left debug panel.

## 🚀 Extending the System

To add a new input source:

1. **Create a class implementing `InputSource`**:
```dart
class MyCustomInput implements InputSource {
  @override
  void Function(TouchInputEvent)? onInput;
  
  @override
  void start() { /* setup */ }
  
  @override
  void stop() { /* cleanup */ }
}
```

2. **Initialize in `_initializeInputSources()`**
3. **Add color mapping in `addTouchEffect()`**
4. **Add stats tracking in `_handleInputEvent()`**

## 📝 Notes

- UDP mapping is specific to UDP input - local inputs always use direct coordinates
- The mapping formula is linear interpolation between ranges
- All input events go through the same `_handleInputEvent()` method
- Effects are rendered by the Flame game engine with position components

## 🎉 Testing Checklist

- [ ] UDP input works with mapping enabled
- [ ] UDP input works with mapping disabled
- [ ] Mouse clicks create orange effects at click position
- [ ] Touch/drag creates continuous pink effects
- [ ] Toggle switches enable/disable each source
- [ ] Stats counters update correctly
- [ ] Debug log shows all input sources
- [ ] Colors help identify input sources

Happy testing! 🚀
