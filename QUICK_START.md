# Quick Start Guide - LED Interactive Demo

## 🚀 Testing on macOS (Your Current System)

### Option 1: Quick Test (Easiest)

**Terminal 1** - Run the app:
```bash
cd /Users/mohn93/Desktop/led_screen_test
flutter run -d macos
```

**Terminal 2** - Send test data:
```bash
cd /Users/mohn93/Desktop/led_screen_test
python3 quick_test.py
```

This sends the example packets from the protocol documentation and animated coordinates.

### Option 2: Interactive Test

For more testing options:
```bash
python3 test_udp_sender.py
```

Then choose from:
1. Protocol documentation examples
2. Single point (circle pattern)
3. Two points (opposite movement)
4. Random multi-point
5. Continuous random stream

---

## 🪟 Testing on Windows

### Run the app:
```cmd
cd C:\path\to\led_screen_test
flutter run -d windows
```

### Send test data:
```cmd
python test_udp_sender.py
```

---

## 🔌 Testing with Real Hardware

1. **Find your Mac's IP address**:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Example output: `inet 192.168.1.100`

2. **Configure LED sensor** to send UDP packets to:
   - IP: `192.168.1.100` (your actual IP)
   - Port: `25000`

3. **Check firewall** (if not receiving data):
   - System Preferences > Security & Privacy > Firewall
   - Allow incoming connections for the app

---

## 📊 What to Look For in the App

✅ **Status Card** (top):
- Green indicator = Listening successfully
- Packets received = Should increment when data arrives
- Active touch points = Number of simultaneous touches

✅ **Touch Points List**:
- Shows X, Y coordinates
- Timestamp for each point
- Updates in real-time

✅ **Raw Data** (bottom):
- Hex dump of last received packet
- Useful for debugging protocol issues

---

## 🐛 Troubleshooting

### No data received?

**Check if port is in use:**
```bash
lsof -i :25000
```

**Check firewall:**
- Temporarily disable to test
- Or add exception for the app

**Test with local packets:**
```bash
python3 quick_test.py
```

### App won't start?

**Check Flutter setup:**
```bash
flutter doctor
```

**Clean and rebuild:**
```bash
flutter clean
flutter pub get
flutter run -d macos
```

---

## 📝 Files Overview

- `lib/main.dart` - Main app code
- `quick_test.py` - Simple test script (recommended)
- `test_udp_sender.py` - Interactive test with multiple modes
- `LED_DEMO_README.md` - Complete documentation
- `resources/` - Protocol specifications

---

## 🎯 Next Steps

Once you confirm the integration works:

1. **Visual Feedback**: Add canvas to show touch points visually
2. **Calibration**: Map sensor coordinates to screen coordinates
3. **Gestures**: Detect swipes, taps, multi-touch patterns
4. **Recording**: Log touch data for analysis
5. **Custom UI**: Build your interactive application

---

## 💡 Tips

- The `quick_test.py` script is fastest for verification
- Use `test_udp_sender.py` for continuous testing
- Raw hex data helps debug protocol issues
- Port 25000 must be free (check with `lsof -i :25000`)
- Sensor and computer must be on same network

---

## 🆘 Need Help?

1. Check `LED_DEMO_README.md` for detailed info
2. Review protocol docs in `resources/`
3. Use raw hex data to debug packet format
4. Test locally first with Python scripts

**Happy Testing! 🎉**
