import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String host;
  final int port;

  ApiService({required this.host, this.port = 5000});

  String get _baseUrl => 'http://$host:$port';

  /// Get list of available videos from the server
  Future<List<String>> getAvailableVideos() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/videos'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['videos']);
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Play a specific video
  Future<void> playVideo(
    String videoName, {
    bool loop = true,
    double? brightness,
    double? playbackFps,
  }) async {
    try {
      final body = {
        'video': videoName,
        'loop': loop,
        if (brightness != null) 'brightness': brightness,
        if (playbackFps != null) 'playback_fps': playbackFps,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/play'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to play video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Stop current playback
  Future<void> stopPlayback() async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/api/stop'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to stop playback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get current playback status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
