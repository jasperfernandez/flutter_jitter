# 📡 Jitter a Flutter Laravel Reverb WebSocket Client

## 🚀 Features

✔️ **Easy WebSocket Connection** to Laravel Reverb  
✔️ **Authentication Support** (JWT, API Keys)  
✔️ **Public & Private Channel Subscriptions**  
✔️ **Real-time Event Handling**  
✔️ **Lightweight & Easy to Use**

## 📦 Installation

Add **flutter_jitter** to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_jitter: ^0.0.1
```

and run:

```sh
flutter pub get
```

or install it from the command line:

```sh
flutter pub add flutter_jitter
```

## 🎯 Usage

### 1️⃣ **Initialize the WebSocket Client**

```dart
import 'package:flutter_jitter/flutter_jitter.dart';

final options = FlutterJitterOptions(
  scheme: "ws",
  host: "localhost",
  port: "8080",
  appKey: "your-app-key", // Reverb app key
  authUrl: "https://your-backend.com/api/broadcasting/auth", // optional, needed for private channels
  authToken: "your-auth-token", // optional
  privatePrefix: "private-", // default: "private-"
);

final jitter = FlutterJitter(options: options);
```

### 2️⃣ **Listen for Messages**

```dart
// Public channel
jitter.listen((message) {
  print("Received: ${message.event}, Data: ${message.data}");
}, "public-channel", isPrivate: false);

// Private channel
jitter.listen((message) {
print("Received: ${message.event}, Data: ${message.data}");
}, "public-channel", isPrivate: true);
```

### 3️⃣ **Close Connection**

```dart
jitter.close();
```

## 🧪 Testing

Unit tests are included and use `mockito` to simulate WebSocket interactions: TODO

```sh
flutter test
```

## 🛠 Configuration

| Parameter       | Type    | Description                                              |
| --------------- | ------- | -------------------------------------------------------- |
| `scheme`        | String  | WebSocket scheme (`ws` or `wss`)                         |
| `host`          | String  | Server hostname                                          |
| `port`          | String  | Server port                                              |
| `appKey`        | String  | Laravel Echo app key                                     |
| `authUrl`       | String? | URL for authentication (private channels)                |
| `authToken`     | String? | Token for authentication requests (`sanctum` or similar) |
| `privatePrefix` | String  | Prefix for private channels (default: `private-`)        |

### FlutterJitterOptions example

```dart
class FlutterJitterOptions {
  final String scheme;
  final String host;
  final String port;
  final String appKey;
  final dynamic authToken;
  final String? authUrl;
  final String privatePrefix;
  final bool usePrefix;

  FlutterJitterOptions({
    required this.scheme,
    required this.host,
    required this.port,
    required this.appKey,
    this.authToken,
    this.authUrl,
    this.privatePrefix = 'private-',
    this.usePrefix = true,
  });
}
```
