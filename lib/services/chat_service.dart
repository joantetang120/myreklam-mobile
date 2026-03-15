import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';
import '../config/api_config.dart';
import 'chat_notification_service.dart';

class ChatService {
  static PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  static final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  // 🟢 Gestion des utilisateurs en ligne via Presence Channel
  static Set<int> onlineUserIds = {};
  static final Set<String> _subscribedChannels = {};

  static Stream<Map<String, dynamic>> get messageStream =>
      _messageController.stream;

  // Initialiser Pusher avec Presence Channel
  static Future<void> initializePusher() async {
    try {
      // Nettoyer les anciens abonnements au cas où
      await clearAllSubscriptions();

      // Récupérer le token pour l'authentification
      final token = await TokenStorage.getAccessToken();

      await _pusher.init(
        apiKey:
            'ec0a59c0a412bc2e435f', // Utiliser la même clé que WebSocketService
        cluster: 'mt1',
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: (dynamic event) {
          if (event is PusherEvent) {
            onEvent(event);
          }
        },
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        // 🔑 Configuration pour Presence Channel
        authEndpoint: '${ApiConfig.baseUrl}/broadcasting/auth',
        onAuthorizer: (channelName, socketId, options) async {
          // Faire une requête HTTP complète pour l'authentification
          try {
            print('🔐 Authentification Pusher...');
            print('   Channel: $channelName');
            print('   Socket ID: $socketId');

            final response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/broadcasting/auth'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'socket_id': socketId,
                'channel_name': channelName,
              }),
            );

            print('🔐 Réponse auth: ${response.statusCode}');
            print('   Body: ${response.body}');

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              return data;
            } else {
              print('❌ Erreur auth: ${response.statusCode} - ${response.body}');
              return null;
            }
          } catch (e) {
            print('❌ Exception auth: $e');
            return null;
          }
        },
      );

      await _pusher.connect();
      print('✅ Pusher connecté');

      // 🟢 S'abonner au Presence Channel
      // await _pusher.subscribe(
      //   channelName: 'presence-online-users',
      //   onEvent: (dynamic event) {
      //     if (event is PusherEvent) {
      //       onEvent(event);
      //     }
      //   },
      // );

      // await _pusher.connect();

      // print('✅ Pusher connecté avec Presence Channel');
    } catch (e) {
      print('❌ Erreur initialisation Pusher: $e');
    }
  }

  // S'abonner à une conversation privée
  static Future<void> subscribeToConversation(String conversationId) async {
    try {
      final channelName = 'conversation.$conversationId';

      // Vérifier si déjà abonné
      if (_subscribedChannels.contains(channelName)) {
        print('⚠️ Déjà abonné à: $channelName');
        return;
      }

      print('🔔 Abonnement au canal: $channelName');
      print('   Canaux déjà abonnés: $_subscribedChannels');

      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (dynamic event) {
          print('📨 Événement reçu sur $channelName: ${event.runtimeType}');
          if (event is PusherEvent) {
            print('   EventName: ${event.eventName}');
            print('   ChannelName: ${event.channelName}');
            print('   Data: ${event.data}');
            onEvent(event);
          }
        },
      );

      _subscribedChannels.add(channelName);
      print('✅ Abonné à: $channelName');
      print('   Canaux abonnés: $_subscribedChannels');
    } catch (e) {
      print('❌ Erreur abonnement conversation: $e');
      rethrow;
    }
  }

  // Se désabonner d'une conversation
  static Future<void> unsubscribeFromConversation(String conversationId) async {
    try {
      final channelName = 'conversation.$conversationId';

      await _pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);

      print('✅ Désabonné de la conversation $conversationId');
    } catch (e) {
      print('❌ Erreur désabonnement: $e');
    }
  }

  // Nettoyer tous les abonnements (utilisé au démarrage)
  static Future<void> clearAllSubscriptions() async {
    try {
      for (final channelName in _subscribedChannels) {
        await _pusher.unsubscribe(channelName: channelName);
        print('🧹 Nettoyé: $channelName');
      }
      _subscribedChannels.clear();
      print('✅ Tous les abonnements nettoyés');
    } catch (e) {
      print('❌ Erreur nettoyage abonnements: $e');
    }
  }

  // 🟢 S'abonner au Presence Channel pour les statuts en ligne
  static Future<void> subscribeToPresenceChannel() async {
    try {
      const channelName = 'presence-online-users';

      print('📡 Abonnement au Presence Channel: $channelName');

      // Les événements sont gérés globalement via onEvent dans init()
      await _pusher!.subscribe(channelName: channelName);

      print('✅ Abonné au Presence Channel');
    } catch (e) {
      print('❌ Erreur abonnement Presence Channel: $e');
    }
  }

  // Vérifier si un utilisateur est en ligne
  static bool isUserOnline(int userId) {
    return onlineUserIds.contains(userId);
  }

  // Obtenir le nombre d'utilisateurs en ligne
  static int getOnlineUsersCount() {
    return onlineUserIds.length;
  }

  // Callbacks Pusher
  static void onConnectionStateChange(
    dynamic currentState,
    dynamic previousState,
  ) {
    print('🔄 Pusher état: $previousState -> $currentState');
  }

  static void onError(String message, int? code, dynamic e) {
    print('❌ Pusher erreur: $message (code: $code)');
  }

  static void onEvent(PusherEvent event) {
    print('📨 Pusher événement global: ${event.eventName}');
    print('   Canal: ${event.channelName}');
    print('   Data: ${event.data}');
    print('   Timestamp: ${DateTime.now()}');

    // Ignorer les événements système Pusher (gérés par les callbacks onMemberAdded/onMemberRemoved)
    if (event.eventName.startsWith('pusher:')) {
      print('   ⚠️ Événement système ignoré');
      return;
    }

    switch (event.eventName) {
      case 'new.message':
        {
          print('✅ New message détecté - Traitement...');

          // Parser les données de l'événement Laravel
          final eventData = json.decode(event.data);
          final messageData = eventData['message'];
          final senderData = eventData['sender'];

          // Extraire l'ID de conversation du nom du canal
          // Format: private-conversation.7 -> 7
          final channelName = event.channelName;
          if (channelName.startsWith('conversation.')) {
            final conversationId = channelName.replaceFirst(
              'conversation.',
              '',
            );

            print('   Conversation ID: $conversationId');
            print('   Message ID: ${messageData['id']}');
            print('   Sender ID: ${senderData['id']}');

            // Ajouter les données complètes au stream
            _messageController.add({
              'conversationId': conversationId,
              'message': messageData,
              'sender': senderData,
              'type': 'new_message',
            });

            // Gérer les notifications globalement
            _handleNotification(messageData, senderData, conversationId);
          } else {
            print('⚠️ Format de canal invalide: $channelName');
          }
        }
        break;
      case 'message.status.updated':
        {
          print('✅ Message.status.updated détecté - Traitement...');

          // Extraire l'ID de conversation du nom du canal
          // Format: conversation.7 -> 7
          final channelName = event.channelName;
          if (channelName.startsWith('conversation.')) {
            final conversationId = channelName.replaceFirst(
              'conversation.',
              '',
            );

            print('   Conversation ID: $conversationId');
            print('   Data: ${event.data}');

            // Ajouter au stream pour mettre à jour les statuts
            _messageController.add({
              'conversationId': conversationId,
              'type': 'status_update',
              'data': event.data,
            });
          } else {
            print('⚠️ Format de canal invalide: $channelName');
          }
        }
        break;
      default:
        print('⚠️ Événement non géré: ${event.eventName}');
        break;
    }
  }

  // Récupérer l'ID de l'utilisateur actuel
  static Future<int?> getCurrentUserId() async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return int.tryParse(data['user']['id']);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Ensemble pour suivre les messages déjà notifiés
  static final Set<String> _notifiedMessages = {};

  static Future<void> _handleNotification(
    dynamic messageData,
    dynamic senderData,
    String conversationId,
  ) async {
    try {
      // Récupérer l'ID du message pour éviter les doublons
      final messageId = messageData['id']?.toString();
      if (messageId != null) {
        final notificationKey = '${conversationId}_$messageId';
        if (_notifiedMessages.contains(notificationKey)) {
          print('🔔 Notification déjà envoyée pour le message $messageId');
          return;
        }
        _notifiedMessages.add(notificationKey);

        // Nettoyer les anciennes notifications (garder seulement les 100 dernières)
        if (_notifiedMessages.length > 100) {
          _notifiedMessages.removeAll(
            _notifiedMessages.take(_notifiedMessages.length - 100).toList(),
          );
        }
      }

      // Récupérer l'ID de l'expéditeur
      final senderId = messageData['sender_id'] ?? senderData?['id'];
      if (senderId == null) {
        print('⚠️ Notification ignorée - Sender ID manquant');
        return;
      }

      // Récupérer le nom de l'expéditeur
      final senderName =
          senderData?['name'] ??
          senderData?['email'] ??
          'Utilisateur $senderId';

      // Récupérer le contenu du message
      final content = messageData['text'] ?? messageData['content'] ?? '';
      final currentUserId = await getCurrentUserId() ?? 0;

      print('🔔 Notification chat:');
      print('   De: $senderName (ID: $senderId)');
      print('   Message: $content');
      print('   Conversation: $conversationId');

      // Utiliser les notifications locales uniquement
      print('🔔 Envoi notification locale...');

      // Utiliser le service de notifications avec logique intelligente
      await ChatNotificationService.instance.showSmartNotification(
        senderName: senderName,
        message: content,
        conversationId: conversationId,
        currentUserId: currentUserId,
        senderId: senderId!,
        currentConversationId: null, // TODO: Détecter la conversation active
      );

      print('🔔 Notification locale envoyée');
    } catch (e) {
      print('❌ Erreur notification: $e');
    }
  }

  static void onSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ Abonnement réussi: $channelName');

    // 🟢 Récupérer la liste initiale des membres en ligne
    if (channelName == 'presence-online-users') {
      try {
        print('👥 Data reçue: $data');

        onlineUserIds.clear();

        // Parser la structure Pusher: {presence: {hash: {...}}}
        Map<String, dynamic>? parsedData;

        if (data is String) {
          parsedData = jsonDecode(data) as Map<String, dynamic>;
        } else if (data is Map) {
          parsedData = Map<String, dynamic>.from(data);
        }

        if (parsedData != null) {
          // Extraire le hash des membres
          final presence = parsedData['presence'];
          if (presence != null && presence is Map) {
            final hash = presence['hash'];
            if (hash != null && hash is Map) {
              // hash est un Map {user_id: {id, name, avatar}}
              hash.forEach((key, value) {
                if (value is Map && value['id'] != null) {
                  final userId = value['id'];
                  int userIdInt;

                  if (userId is int) {
                    userIdInt = userId;
                  } else if (userId is double) {
                    userIdInt = userId.toInt();
                  } else if (userId is String) {
                    userIdInt = int.parse(userId);
                  } else {
                    return;
                  }

                  onlineUserIds.add(userIdInt);
                  print('   ✅ User $userIdInt ajouté');
                }
              });
            }
          }
        }

        print(
          '👥 ${onlineUserIds.length} utilisateurs en ligne: $onlineUserIds',
        );

        // Notifier les listeners
        _messageController.add({
          'type': 'presence_update',
          'action': 'initial',
          'onlineUsers': onlineUserIds.toList(),
        });
      } catch (e) {
        print('❌ Erreur parsing members: $e');
      }
    }
  }

  static void onSubscriptionError(String message, dynamic e) {
    print('❌ Erreur abonnement: $message');
  }

  static void onDecryptionFailure(String event, String reason) {
    print('❌ Échec déchiffrement: $event - $reason');
  }

  // Utilitaire: parser un userId dynamique en int
  static int? _parseUserId(dynamic userId) {
    if (userId == null) return null;

    if (userId is int) {
      return userId;
    } else if (userId is double) {
      return userId.toInt();
    } else if (userId is String) {
      return int.tryParse(userId);
    }

    return null;
  }

  // Utilitaire: appliquer l'ajout d'un membre en ligne
  static void _applyMemberAdded(int userIdInt) {
    onlineUserIds.add(userIdInt);

    print('🟢 User $userIdInt est maintenant EN LIGNE');
    print('👥 Total en ligne: ${onlineUserIds.length}');

    _messageController.add({
      'type': 'presence_update',
      'action': 'member_added',
      'userId': userIdInt,
      'onlineUsers': onlineUserIds.toList(),
    });
  }

  // Utilitaire: appliquer le retrait d'un membre en ligne
  static void _applyMemberRemoved(int userIdInt, {String? lastSeen}) {
    onlineUserIds.remove(userIdInt);

    final lastSeenTime = lastSeen ?? DateTime.now().toIso8601String();

    print('🔴 User $userIdInt est maintenant HORS LIGNE');
    print('👥 Total en ligne: ${onlineUserIds.length}');
    print('🕐 Last seen: $lastSeenTime');

    _messageController.add({
      'type': 'presence_update',
      'action': 'member_removed',
      'userId': userIdInt,
      'lastSeen': lastSeenTime,
      'onlineUsers': onlineUserIds.toList(),
    });
  }

  // 🟢 Callback Pusher: membre ajouté au canal presence
  static void onMemberAdded(String channelName, PusherMember member) {
    print('👤 Membre ajouté: ${member.userId} sur $channelName');

    // 🟢 Quelqu'un se connecte
    if (channelName == 'presence-online-users') {
      try {
        print('👤 UserInfo: ${member.userInfo}');

        dynamic userInfo;
        if (member.userInfo is String) {
          userInfo = jsonDecode(member.userInfo!);
        } else {
          userInfo = member.userInfo;
        }

        if (userInfo != null && userInfo['id'] != null) {
          final userIdInt = _parseUserId(userInfo['id']);
          if (userIdInt == null) return;

          _applyMemberAdded(userIdInt);
        }
      } catch (e) {
        print('❌ Erreur onMemberAdded: $e');
      }
    }
  }

  static void onMemberRemoved(String channelName, PusherMember member) {
    print('👤 Membre retiré: ${member.userId} de $channelName');

    // 🔴 Quelqu'un se déconnecte
    if (channelName == 'presence-online-users') {
      try {
        print('👤 UserInfo: ${member.userInfo}');

        dynamic userInfo;
        if (member.userInfo is String) {
          userInfo = jsonDecode(member.userInfo!);
        } else {
          userInfo = member.userInfo;
        }

        if (userInfo != null && userInfo['id'] != null) {
          final userIdInt = _parseUserId(userInfo['id']);
          if (userIdInt == null) return;

          _applyMemberRemoved(userIdInt);
        }
      } catch (e) {
        print('❌ Erreur onMemberRemoved: $e');
      }
    }
  }

  // Nettoyer les ressources
  static Future<void> dispose() async {
    await _pusher?.disconnect();
    await _messageController.close();
  }
}
