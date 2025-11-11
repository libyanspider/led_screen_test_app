# LED Interactive Screen Demo App

This Flutter application demonstrates integration with the LED Interactive Flood Material protocol by listening to UDP packets on port 25000 and displaying touch coordinates in real-time.

## Features

- ✅ Listens on UDP port 25000 for interactive touch data
- ✅ Parses binary protocol according to LED Interactive specifications
- ✅ Displays touch coordinates in real-time
- ✅ Shows packet count and connection status
- ✅ Displays raw hex data for debugging
- ✅ Supports multiple simultaneous touch points

## Protocol Details

The app implements the LED Interactive Flood Material protocol:

- **Port**: UDP 25000
- **Data Format** (Little-endian):
  - Bytes 0-1: Frame number (ignored)
  - Bytes 2-3: Ignore field (01 00)
  - Bytes 4-5: Number of touch points
  - For each point:
    - 2 bytes: X coordinate
    - 2 bytes: Y coordinate

### Example Protocol Data

**Example 1**: Single Point
```
86 55 01 00 01 00 1D 01 05 00
```
- Frame: 0x5586
- Points: 1
- Point 1: X=285 (0x011D), Y=5 (0x0005)

**Example 2**: Two Points
```
CA 56 01 00 02 00 F5 00 05 00 FF 00 0F 00
```
- Frame: 0x56CA
- Points: 2
- Point 1: X=245 (0x00F5), Y=5 (0x0005)
- Point 2: X=255 (0x00FF), Y=15 (0x000F)

## Running the App

### Prerequisites

1. Flutter SDK installed and configured
2. Platform development tools set up (macOS/Windows)

### Steps

1. **Navigate to the project directory**:
   ```bash
   cd /Users/mohn93/Desktop/led_screen_test
   ```

2. **Get dependencies** (should already be satisfied):
   ```bash
   flutter pub get
   ```

3. **Run the app**:

   **On macOS**:
   ```bash
   flutter run -d macos
   ```

   Or build a release version:
   ```bash
   flutter build macos
   ```

   The app will be located at:
   ```
   build/macos/Build/Products/Release/led_screen_test.app
   ```

   **On Windows**:
   ```bash
   flutter run -d windows
   ```

   Or build a release version:
   ```bash
   flutter build windows
   ```

   The executable will be located at:
   ```
   build/windows/x64/runner/Release/led_screen_test.exe
   ```

## Configuration for LED Interactive Hardware

To receive data from your LED interactive sensor:

1. **Ensure both devices are on the same network**

2. **Find your computer's IP address**:
   
   **On macOS**:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Or check System Preferences > Network
   
   **On Windows**:
   ```cmd
   ipconfig
   ```
   Look for the IPv4 Address (e.g., 192.168.1.100)

3. **Configure the LED sensor** to send UDP packets to:
   - **IP Address**: Your computer's IP
   - **Port**: 25000

4. **Firewall**: You may need to allow incoming UDP traffic on port 25000:
   
   **On macOS**:
   - Go to System Preferences > Security & Privacy > Firewall
   - Click "Firewall Options"
   - Add the app or allow incoming connections
   - Or temporarily disable the firewall for testing
   
   **On Windows**:
   ```cmd
   netsh advfirewall firewall add rule name="LED Interactive UDP" dir=in action=allow protocol=UDP localport=25000
   ```

## Using the App

Once the app is running:

1. **Status Card** (top):
   - Green indicator: Successfully listening on port 25000
   - Packets received: Count of UDP packets received
   - Active touch points: Number of simultaneous touch points

2. **Touch Points List**:
   - Displays each touch point with X, Y coordinates
   - Shows timestamp when the point was received
   - Updates in real-time as new data arrives

3. **Raw Data Display** (bottom):
   - Shows the last received packet in hexadecimal format
   - Useful for debugging protocol issues

## Testing Without Hardware

To test the app without actual LED hardware, you can send test UDP packets using Python or netcat:

### Python Test Script

```python
import socket
import struct

# Create UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Target: localhost on port 25000
target = ('127.0.0.1', 25000)

# Example: Single point at X=285, Y=5
# Format: [frame(2)] [ignore(2)] [num_points(2)] [x(2)] [y(2)]
data = struct.pack('<HHHHH', 0x5586, 0x0001, 0x0001, 0x011D, 0x0005)

# Send packet
sock.sendto(data, target)
print(f"Sent test packet: {data.hex()}")

sock.close()
```

### PowerShell Test (Windows)

```powershell
$udpClient = New-Object System.Net.Sockets.UdpClient
$data = [byte[]](0x86, 0x55, 0x01, 0x00, 0x01, 0x00, 0x1D, 0x01, 0x05, 0x00)
$udpClient.Send($data, $data.Length, "127.0.0.1", 25000)
$udpClient.Close()
```

## Troubleshooting

### App shows "Listening on port 25000" but no data

1. Check firewall settings
2. Verify the LED sensor is configured to send to the correct IP address
3. Ensure both devices are on the same network
4. Check if port 25000 is already in use:
   ```cmd
   netstat -an | findstr :25000
   ```

### "Error: SocketException"

- Port 25000 may already be in use by another application
- Try closing other applications or restart your computer
- On macOS, check with: `lsof -i :25000`
- On Windows, check with: `netstat -an | findstr :25000`

### Data appears corrupted

- Check the "Last Raw Data" section to see the actual hex values
- Compare with the protocol specification in `resources/interactive_information_protocol.md`
- Verify little-endian byte order

## Project Structure

```
led_screen_test/
├── lib/
│   └── main.dart              # Main app with UDP listener and UI
├── resources/
│   ├── interactive_information_protocol.md
│   └── led_interactive_flood_material.md
├── windows/                   # Windows-specific files
└── pubspec.yaml              # Dependencies
```

## Code Overview

The main components of `main.dart`:

- **TouchPoint class**: Represents a single touch coordinate with timestamp
- **LEDInteractiveDemo**: Main UI widget
- **_startListening()**: Binds UDP socket to port 25000
- **_processData()**: Parses binary protocol and extracts coordinates
- **build()**: Displays status, touch points, and raw data

## Next Steps

After verifying the integration works:

1. Add visual representation (draw touch points on canvas)
2. Add coordinate mapping/calibration
3. Implement touch event callbacks
4. Add logging/recording capabilities
5. Create custom touch gestures

## License

This is a demo application for testing LED Interactive hardware integration.
