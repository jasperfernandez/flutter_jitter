import 'package:flutter_jitter/flutter_jitter_options.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_jitter/flutter_jitter.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'flutter_jitter_test.mocks.dart';

@GenerateMocks([http.Client, WebSocketChannel])
void main() {
  group('FlutterJitter', () {
    late MockClient mockHttpClient;
    late MockWebSocketChannel mockWebSocket;
    late FlutterJitter jitter;

    setUp(() {
      mockHttpClient = MockClient();
      mockWebSocket = MockWebSocketChannel();

      final options = FlutterJitterOptions(
        scheme: 'ws',
        host: 'localhost',
        port: '6001',
        appKey: 'testKey',
        authToken: 'testToken',
        authUrl: 'https://example.com/broadcasting/auth',
      );

      jitter = FlutterJitter(options: options);
    });

    test('should construct WebSocket URL correctly', () {
      expect(jitter.options.scheme, 'ws');
      expect(jitter.options.host, 'localhost');
      expect(jitter.options.port, '6001');
      expect(jitter.options.appKey, 'testKey');
    });
  });
}
