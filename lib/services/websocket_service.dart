import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myreklam/config/api_config.dart';

class WebSocketService {
  static PusherChannelsFlutter? _pusher;
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static final Map<String, Function(Map<String, dynamic>)> _messageHandlers =
      {};
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    if (_isInitialized) return;

    _pusher = PusherChannelsFlutter.getInstance();

    await _pusher!.init(
      apiKey: 'ec0a59c0a412bc2e435f',
      cluster: 'mt1',
      onConnectionStateChange: onConnectionStateChange,
      onError: onError,
      onEvent: onEvent,
      onAuthorizer: onAuthorizer,
    );

    _isInitialized = true;
    print('✅ WebSocketService initialized');
  }

  static dynamic onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = await _getAuthToken();
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');

    final response = await http.post(
      Uri.parse('$baseUrl/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'socket_id': socketId, 'channel_name': channelName}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Authorization failed: ${response.statusCode}');
    }
  }

  static Future<void> connect() async {
    if (!_isInitialized) await init();

    try {
      await _pusher!.connect();
      print('🔌 Connecting to Pusher...');
    } catch (e) {
      print('❌ Connection error: $e');
    }
  }

  static Future<void> disconnect() async {
    if (_pusher != null) {
      await _pusher!.disconnect();
      _isConnected = false;
      print('🔌 Disconnected from Pusher');
    }
  }

  static Future<void> subscribeToConversation(
    String conversationId,
    Function(Map<String, dynamic>) onMessage,
  ) async {
    if (!_isInitialized) await init();

    final channelName = 'private-conversation.$conversationId';
    _messageHandlers[channelName] = onMessage;

    try {
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: onEvent,
        onSubscriptionSucceeded: (channelName, data) {
          print('✅ Subscribed to $channelName');
        },
        onSubscriptionError: (channelName, message, e) {
          print('❌ Subscription error on $channelName: $message');
          print('Error details: $e');
        },
      );
    } catch (e) {
      print('❌ Subscribe error: $e');
    }
  }

  static Future<void> unsubscribeFromConversation(String conversationId) async {
    final channelName = 'private-conversation.$conversationId';

    try {
      await _pusher?.unsubscribe(channelName: channelName);
      _messageHandlers.remove(channelName);
      print('🔕 Unsubscribed from $channelName');
    } catch (e) {
      print('❌ Unsubscribe error: $e');
    }
  }

  static void onConnectionStateChange(
    String currentState,
    String previousState,
  ) {
    print('🔄 Connection state: $previousState → $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  static void onError(String message, int? code, dynamic e) {
    print('❌ Pusher error: $message (code: $code)');
    if (e != null) print('Error details: $e');
  }

  static void onEvent(PusherEvent event) {
    print('📨 Event: "${event.eventName}" on "${event.channelName}"');
    print('📦 Event data: ${event.data}');

    // Vérifier si c'est un événement de nouveau message
    final isNewMessage = event.eventName.contains('new.message');

    if (isNewMessage && event.data != null) {
      final handler = _messageHandlers[event.channelName];
      if (handler != null) {
        try {
          final data = json.decode(event.data!) as Map<String, dynamic>;
          handler(data);
        } catch (e) {
          print('❌ Error parsing event data: $e');
        }
      } else {
        print('⚠️ No handler found for ${event.channelName}');
      }
    }
  }

  static Future<String?> _getAuthToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      print('❌ Error reading auth token: $e');
      return null;
    }
  }

  static bool get isConnected => _isConnected;
  static bool get isInitialized => _isInitialized;
}
