import 'dart:io';
import 'dart:typed_data';
import 'input_source.dart';
import '../models/touch_input_event.dart';

/// UDP Input Source with coordinate mapping for LED interactive sensors
class UDPInputSource implements InputSource {
  @override
  void Function(TouchInputEvent)? onInput;
  
  RawDatagramSocket? _socket;
  bool _isActive = false;
  
  // Mapping configuration
  bool enableMapping;
  double sensorMinX;
  double sensorMaxX;
  double sensorMinY;
  double sensorMaxY;
  double targetMinX;
  double targetMaxX;
  double targetMinY;
  double targetMaxY;
  
  // Debug callbacks
  void Function(String)? onDebugLog;
  void Function(int x, int y)? onRawCoordinate;
  
  UDPInputSource({
    this.enableMapping = true,
    this.sensorMinX = 16.0,
    this.sensorMaxX = 1392.0,
    this.sensorMinY = 1728.0,
    this.sensorMaxY = 3504.0,
    this.targetMinX = 0.0,
    this.targetMaxX = 1711.0,
    this.targetMinY = 1684.0,
    this.targetMaxY = 3368.0,
  });
  
  @override
  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 25000);
      _isActive = true;
      
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _socket!.receive();
          if (datagram != null) {
            _processData(datagram.data);
          }
        }
      });
    } catch (e) {
      onDebugLog?.call('UDP Error: $e');
    }
  }
  
  @override
  void stop() {
    _socket?.close();
    _isActive = false;
  }
  
  void _processData(Uint8List data) {
    try {
      if (data.length < 6) return;
      
      int numPoints = data[4] | (data[5] << 8);
      int expectedLength = 6 + (numPoints * 4);
      if (data.length < expectedLength) return;
      
      for (int i = 0; i < numPoints; i++) {
        int offset = 6 + (i * 4);
        int x = data[offset] | (data[offset + 1] << 8);
        int y = data[offset + 2] | (data[offset + 3] << 8);
        
        // Track raw coordinates
        onRawCoordinate?.call(x, y);
        
        // Map coordinates if enabled
        double mappedX = x.toDouble();
        double mappedY = y.toDouble();
        
        if (enableMapping) {
          mappedX = targetMinX + 
              ((x - sensorMinX) / (sensorMaxX - sensorMinX)) * 
              (targetMaxX - targetMinX);
          
          mappedY = targetMinY + 
              ((y - sensorMinY) / (sensorMaxY - sensorMinY)) * 
              (targetMaxY - targetMinY);
        }
        
        onDebugLog?.call('UDP: Raw($x, $y) -> Mapped(${mappedX.toInt()}, ${mappedY.toInt()})');
        
        // Send input event
        onInput?.call(TouchInputEvent(
          x: mappedX,
          y: mappedY,
          source: 'udp',
        ));
      }
    } catch (e) {
      onDebugLog?.call('UDP Parse Error: $e');
    }
  }
  
  bool get isActive => _isActive;
}
