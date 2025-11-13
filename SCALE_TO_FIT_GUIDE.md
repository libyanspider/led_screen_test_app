# Scale-to-Fit Feature Guide

## Overview

The scale-to-fit feature allows you to scale the dual-screen setup down to fit any window size, making it perfect for development and testing on different displays.

## Virtual Screen Dimensions

The system uses a virtual coordinate space based on the UDP target ranges:

- **Total Virtual Width**: 1711 pixels
- **Total Virtual Height**: 3368 pixels (1684 + 1684)
  - **Top Screen**: Y 0 to 1684
  - **Bottom Screen**: Y 1684 to 3368

## How It Works

### When Scale-to-Fit is ENABLED (Default)

1. **Coordinate Transformation**: All coordinates (UDP, mouse, touch) are in virtual space and automatically scaled to fit your window
2. **Dynamic Scaling**: The system calculates scale factors:
   - `scaleX = windowWidth / 1711`
   - `scaleY = windowHeight / 3368`
3. **Proportional Scaling**: Both screens maintain their aspect ratio
4. **Screen Separator**: Automatically positioned at the scaled midpoint

### When Scale-to-Fit is DISABLED

1. **1:1 Mapping**: No coordinate transformation applied
2. **Native Resolution**: Perfect for testing on actual hardware with matching display size
3. **Direct Coordinates**: Effects render at exact pixel positions

## UI Controls

Located in the **Debug Panel** (top-left corner):

```
Display Mode:
  ☑ Scale to Fit Window
  [Scaling info displayed below]
```

### Scaling Info Display

- **When ON**: Shows `Virtual: 1711x3368 → Screen: 1920x1080 (112.2%)`
- **When OFF**: Shows `1:1 (No scaling)`

## Use Cases

### Development Mode (Scale-to-Fit ON)
- ✅ Test on laptops with smaller screens
- ✅ See both screens at once in any window size
- ✅ Quickly verify touch effects and mapping
- ✅ Debug coordinate transformations

### Production Mode (Scale-to-Fit OFF)
- ✅ Running on actual dual-screen hardware
- ✅ Pixel-perfect rendering
- ✅ Direct mapping from sensors to displays
- ✅ No performance overhead from scaling

## Coordinate Flow

### UDP Input (with mapping enabled)
```
Sensor Coords → UDP Mapping → Virtual Coords → Scale Transform → Screen Coords → Effects
```

### Local Input (mouse/touch)
```
Screen Coords → Inverse Scale → Virtual Coords → Scale Transform → Screen Coords → Effects
```

## Technical Details

### Files Modified

1. **`lib/game/led_interactive_game.dart`**
   - Added `scaleToFit`, `_scaleX`, `_scaleY` properties
   - Implemented `_transformCoordinates()` method
   - Added `toggleScaleToFit()` and `getScalingInfo()` methods
   - Updates scaling on window resize via `onGameResize()`

2. **`lib/ui/debug_panel.dart`**
   - Added scale toggle checkbox
   - Added scaling info display
   - New "Display Mode" section

3. **`lib/main.dart`**
   - Added `_screenToVirtualCoords()` helper method
   - Converts local input from screen space to virtual space
   - Wires up scale toggle to game state

### Key Methods

```dart
// In LEDInteractiveGame
void toggleScaleToFit(bool scale) {
  scaleToFit = scale;
  _updateScaling();
  _updateSeparator();
}

Vector2 _transformCoordinates(double x, double y) {
  if (scaleToFit) {
    return Vector2(x * _scaleX, y * _scaleY);
  }
  return Vector2(x, y);
}

// In main.dart
Offset _screenToVirtualCoords(double screenX, double screenY) {
  if (game.scaleToFit) {
    final virtualX = screenX / game.size.x * LEDInteractiveGame.virtualWidth;
    final virtualY = screenY / game.size.y * LEDInteractiveGame.virtualHeight;
    return Offset(virtualX, virtualY);
  }
  return Offset(screenX, screenY);
}
```

## Screen Area Selection

Combines with the screen selector:
- **Top Screen**: Only renders effects in top half (Y < 1684)
- **Bottom Screen**: Only renders effects in bottom half (Y >= 1684)
- **Both Screens**: Renders effects anywhere

Filtering happens in virtual space before transformation, ensuring consistent behavior regardless of scaling mode.

## Performance Notes

- **Minimal Overhead**: Simple multiplication for coordinate transformation
- **No Texture Scaling**: Only affects coordinate calculations
- **Real-time Updates**: Scaling recalculates on window resize
- **No Frame Rate Impact**: Maintains 60 FPS in both modes

## Tips

1. **For Development**: Keep scale-to-fit ON and window at comfortable size
2. **For Testing UDP**: Toggle scale OFF if hardware matches virtual dimensions
3. **Window Resizing**: Scaling updates automatically, separator adjusts
4. **Mouse Testing**: Works perfectly in both modes - coordinates auto-convert

## Examples

### Small Window (800x600)
- Virtual: 1711x3368 → Screen: 800x600 (46.7%)
- Everything scales down to fit
- Both screens visible

### Large Window (3840x2160)
- Virtual: 1711x3368 → Screen: 3840x2160 (224.4%)
- Everything scales up
- Sharp, clear rendering

### Native Resolution (1711x3368)
- Virtual: 1711x3368 → Screen: 1711x3368 (100%)
- No scaling needed
- Perfect 1:1 match
