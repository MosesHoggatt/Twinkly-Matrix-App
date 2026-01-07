import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

class CommandSender {
  late RawDatagramSocket _socket;
  final String _host;
  final int _port;

  CommandSender({required String host, int port = 5000})
      : _host = host,
        _port = port;

  /// Initialize the socket connection
  Future<bool> initialize() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      developer.log('CommandSender initialized for $_host:$_port');
      return true;
    } catch (e) {
      developer.log('Failed to initialize CommandSender: $e');
      return false;
    }
  }

  /// Send a command to the Python server
  void sendCommand(String command, {Map<String, dynamic>? params}) {
    try {
      final Map<String, dynamic> payload = {
        'cmd': command,
        if (params != null) ...params,
      };

      final jsonData = jsonEncode(payload);
      final bytes = utf8.encode(jsonData);
      _socket.send(bytes, InternetAddress(_host), _port);

      developer.log('Sent command: $command');
    } catch (e) {
      developer.log('Failed to send command: $e');
    }
  }

  /// Send a raw string command
  void sendRawCommand(String rawCommand) {
    try {
      final bytes = utf8.encode(rawCommand);
      _socket.send(bytes, InternetAddress(_host), _port);
      developer.log('Sent raw command: $rawCommand');
    } catch (e) {
      developer.log('Failed to send raw command: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _socket.close();
  }
}
