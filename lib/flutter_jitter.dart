import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_jitter/flutter_jitter_options.dart';

abstract class ReverbService {
  Future<String?> authenticate(String socketId, String channelName);

  void subscribe(
    String channelName,
    String? broadcastAuthToken, {
    bool isPrivate = false,
  });

  void listen(
    void Function(dynamic) onData,
    String channelName, {
    bool isPrivate = false,
  });

  void close();
}

class FlutterJitter implements ReverbService {
  late final WebSocketChannel _channel;
  final FlutterJitterOptions options;
  final Logger _logger = Logger();

  FlutterJitter({required this.options}) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));
    } catch (e) {
      _logger.e('Failed to connect to WebSocket: $e');
      rethrow;
    }
  }

  String get websocketUrl => buildWebSocketUrl();

  String buildWebSocketUrl({
    String? scheme,
    String? host,
    String? port,
    String? appKey,
  }) {
    var wsScheme = (scheme ?? options.scheme).toLowerCase();
    if (wsScheme == 'http') {
      wsScheme = 'ws';
    } else if (wsScheme == 'https') {
      wsScheme = 'wss';
    }

    final wsHost = host ?? options.host;
    final wsPort = port ?? options.port;
    final wsAppKey = (appKey ?? options.appKey).split('#').first;

    final authority = wsPort.isEmpty ? wsHost : '$wsHost:$wsPort';
    return '$wsScheme://$authority/app/$wsAppKey';
  }

  @override
  void subscribe(
    String channelName,
    String? broadcastAuthToken, {
    bool isPrivate = false,
  }) {
    try {
      final subscription = {
        "event": "pusher:subscribe",
        "data":
            isPrivate
                ? {"channel": channelName, "auth": broadcastAuthToken}
                : {"channel": channelName},
      };
      _channel.sink.add(jsonEncode(subscription));
    } catch (e) {
      _logger.e('Failed to subscribe to channel: $e');
      rethrow;
    }
  }

  @override
  void listen(
    void Function(dynamic) onData,
    String channelName, {
    bool isPrivate = false,
  }) {
    try {
      final channelPrefix = options.usePrefix ? options.privatePrefix : '';
      final fullChannelName =
          isPrivate ? '$channelPrefix$channelName' : channelName;
      subscribe(channelName, null, isPrivate: isPrivate);
      _channel.stream.listen(
        (message) async {
          try {
            final Map<String, dynamic> jsonMessage = jsonDecode(message);
            final response = WebsocketResponse.fromJson(jsonMessage);

            if (response.event == 'pusher:connection_established') {
              final socketId = response.data?['socket_id'];

              if (socketId == null) {
                throw Exception('Socket ID is missing');
              }

              if (isPrivate) {
                final authToken = await authenticate(socketId, fullChannelName);
                subscribe(fullChannelName, authToken!, isPrivate: isPrivate);
              } else {
                subscribe(fullChannelName, null, isPrivate: isPrivate);
              }
            } else if (response.event == 'pusher:ping') {
              _channel.sink.add(jsonEncode({'event': 'pusher:pong'}));
            }
            onData(response);
          } catch (e) {
            _logger.e('Error processing message: $e');
          }
        },
        onError: (error) => _logger.e('WebSocket error: $error'),
        onDone: () => _logger.i('Connection closed: $channelName'),
      );
    } catch (e) {
      _logger.e('Failed to listen to WebSocket: $e');
      rethrow;
    }
  }

  @override
  Future<String?> authenticate(String socketId, String channelName) async {
    try {
      if (options.authToken == null) {
        throw Exception('Auth Token is missing');
      } else if (options.authUrl == null) {
        throw Exception('Auth URL is missing');
      }

      var token = options.authToken;
      if (options.authToken is Future<String?>) {
        token = await options.authToken;
      } else if (options.authToken is String) {
        token = options.authToken;
      } else {
        throw Exception('Parameter authToken is not a string or a function');
      }

      final response = await (http.Client()).post(
        Uri.parse(options.authUrl!),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'socket_id': socketId, 'channel_name': channelName}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['auth'];
      } else {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Authentication error: $e');
      return null;
    }
  }

  @override
  void close() {
    try {
      _channel.sink.close(status.goingAway);
    } catch (e) {
      _logger.e('Failed to close WebSocket: $e');
    }
  }
}

class WebsocketResponse {
  final String event;
  final Map<String, dynamic>? data;

  WebsocketResponse({required this.event, this.data});

  factory WebsocketResponse.fromJson(Map<String, dynamic> json) {
    return WebsocketResponse(
      event: json['event'],
      data: json['data'] != null ? jsonDecode(json['data']) : null,
    );
  }
}
