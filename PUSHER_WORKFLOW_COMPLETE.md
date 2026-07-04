# Workflow Pusher Complet - Chat Temps Réel

## 📋 Vue d'ensemble

Système de chat temps réel avec Flutter (frontend) et Laravel (backend) utilisant Pusher comme service WebSocket.

---

## 🎯 Architecture Générale

```
Flutter App ←→ Laravel Backend ←→ Pusher WebSocket Service
     ↓                ↓                      ↓
  Client WebSocket  Broadcast Events     Real-time Events
```

---

## 🔧 Configuration Backend (Laravel)

### 1. Fichiers de Configuration

#### `.env`
```env
# Configuration Pusher
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=your_app_id
PUSHER_APP_KEY=2d08020d133598a2ee58
PUSHER_APP_SECRET=your_app_secret
PUSHER_HOST=api-{}.pusherapp.com
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=us2

# Queue (sync pour le développement)
QUEUE_CONNECTION=sync
```

#### `config/broadcasting.php` (CRITICAL - était manquant)
```php
<?php
return [
    'default' => env('BROADCAST_DRIVER', 'null'),
    'connections' => [
        'pusher' => [
            'driver' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER'),
                'useTLS' => true,
                'encrypted' => true,
                'host' => env('PUSHER_HOST', 'api-'.env('PUSHER_APP_CLUSTER').'.pusherapp.com'),
                'port' => env('PUSHER_PORT', 443),
                'scheme' => env('PUSHER_SCHEME', 'https'),
            ],
        ],
    ],
];
```

### 2. Modèles

#### `app/Models/Message.php`
```php
protected $fillable = [
    'conversation_id',
    'sender_id', 
    'text',
    'attachments',
    'is_read',  // ← Important pour le statut de lecture
];

protected $casts = [
    'is_read' => 'boolean',
];
```

### 3. Événements de Broadcast

#### `app/Events/NewChatMessage.php`
```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewChatMessage implements ShouldBroadcast  // ← Standard (pas ShouldBroadcastNow)
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $conversation;
    public $message;
    public $sender;

    public function __construct($conversation, $message, $sender)
    {
        $this->conversation = $conversation;
        $this->message = $message;
        $this->sender = $sender;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('conversation.' . $this->conversation->id);
    }

    public function broadcastAs()
    {
        return 'new.message';  // ← Nom de l'événement côté client
    }

    public function broadcastWith()
    {
        return [
            'message' => [
                'id' => $this->message->id,
                'conversation_id' => $this->message->conversation_id,
                'sender_id' => $this->message->sender_id,
                'text' => $this->message->text,
                'created_at' => $this->message->created_at->toISOString(),
                'is_read' => $this->message->is_read,
            ],
            'sender' => [
                'id' => $this->sender->id,
                'name' => $this->sender->name,
            ],
        ];
    }
}
```

### 4. Controllers

#### `app/Http/Controllers/Api/ChatController.php`

**Méthode `sendMessage()`**
```php
public function sendMessage(Request $request, $conversationId)
{
    // 1. Validation
    $request->validate(['text' => 'required|string']);
    
    // 2. Création du message
    $message = Message::create([
        'conversation_id' => $conversationId,
        'sender_id' => auth()->id(),
        'text' => $request->text,
        'is_read' => false,  // ← Non lu par défaut
    ]);
    
    // 3. Mise à jour conversation
    $conversation = Conversation::find($conversationId);
    $conversation->update([
        'last_message' => $message->text,
        'last_message_time' => $message->created_at,
    ]);
    
    // 4. BROADCAST CRITIQUE
    try {
        Log::info('Broadcasting NewChatMessage event...');
        broadcast(new NewChatMessage($conversation, $message, auth()->user()));
        Log::info('NewChatMessage event broadcasted successfully');
    } catch (\Exception $e) {
        Log::error('Broadcast failed: ' . $e->getMessage());
    }
    
    return response()->json(['data' => $message->load('sender')]);
}
```

**Méthode `markAsRead()`**
```php
public function markAsRead($conversationId)
{
    // Marquer tous les messages non lus comme lus
    Message::where('conversation_id', $conversationId)
           ->where('sender_id', '!=', auth()->id())  // Messages des autres
           ->where('is_read', false)
           ->update(['is_read' => true]);
    
    // Mettre à jour le compteur unread
    $conversation = Conversation::find($conversationId);
    $conversation->update(['unread_count' => 0]);
    
    return response()->json(['success' => true]);
}
```

### 5. Routes

#### `routes/api.php`
```php
Route::post('/conversations/{id}/messages', [ChatController::class, 'sendMessage']);
Route::post('/conversations/{id}/read', [ChatController::class, 'markAsRead']);
```

#### `routes/channels.php`
```php
Broadcast::channel('conversation.{id}', function ($user, $id) {
    // Autorisation : l'utilisateur doit être participant de la conversation
    return Conversation::where('id', $id)
                     ->where(function($query) use ($user) {
                         $query->where('user_id', $user->id)
                               ->orWhere('vendor_id', $user->id);
                     })->exists();
});
```

---

## 📱 Configuration Frontend (Flutter)

### 1. Dépendances

#### `pubspec.yaml`
```yaml
dependencies:
  pusher_channels_flutter: ^2.2.0
  provider: ^6.0.5
  http: ^1.1.0
```

### 2. Modèles

#### `lib/models/chat_message.dart`
```dart
class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;  // ← Ajouté pour le statut de lecture

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,  // ← Valeur par défaut
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int currentUserId) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isMe: (json['sender_id'] as int) == currentUserId,
      isRead: json['is_read'] as bool? ?? false,  // ← Parsing du champ is_read
    );
  }
}
```

### 3. Service WebSocket

#### `lib/services/websocket_service.dart`
```dart
class WebSocketService {
  static PusherChannelsFlutter? _pusher;
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};

  static Future<void> init() async {
    if (_isInitialized) return;
    
    _pusher = PusherChannelsFlutter.getInstance();
    await _pusher!.init(
      apiKey: '2d08020d133598a2ee58',
      cluster: 'us2',
      onConnectionStateChange: onConnectionStateChange,
      onError: onError,
      onEvent: onEvent,  // ← Handler principal pour tous les événements
    );
    
    _isInitialized = true;
  }

  static Future<void> subscribeToConversation(
    String conversationId,
    Function(Map<String, dynamic>) onMessage,
  ) async {
    if (!_isInitialized) await init();
    
    _messageHandlers['private-conversation.$conversationId'] = onMessage;
    
    // Authentification requise pour les canaux privés
    final token = await _getAuthToken();
    
    await _pusher!.subscribe(
      channelName: 'private-conversation.$conversationId',
      onEvent: onEvent,
      onSubscriptionSucceeded: (channelName, data) {
        print('✅ Subscribed to $channelName');
      },
      onSubscriptionError: (channelName, message, e) {
        print('❌ Subscription error: $message');
      },
      authEndpoint: 'http://192.168.1.170:8000/api/broadcasting/auth',
      authHeaders: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  static void onEvent(PusherEvent event) {
    // LOGGING COMPLET pour debugging
    print('📨 Event: "${event.eventName}" on "${event.channelName}"');
    print('📦 Event data: ${event.data}');
    
    final isNewMessage = event.eventName.contains('new.message');
    if (isNewMessage && event.data != null) {
      final handler = _messageHandlers[event.channelName];
      if (handler != null) {
        final data = json.decode(event.data!) as Map<String, dynamic>;
        handler(data);
      }
    }
  }
}
```

### 4. Provider

#### `lib/providers/chat_provider.dart`
```dart
class ChatProvider extends ChangeNotifier {
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  
  // Chargement des messages
  Future<void> loadMessages(int conversationId) async {
    // 1. Charger depuis l'API
    // 2. S'abonner au WebSocket
    await WebSocketService.subscribeToConversation(
      conversationId.toString(),
      (data) => _onNewMessage(conversationId, data),
    );
    // 3. Marquer comme lu
    await markAsRead(conversationId);
  }

  // Callback WebSocket
  void _onNewMessage(int conversationId, Map<String, dynamic> data) {
    final newMessage = ChatMessage.fromJson(messageData, currentUserId);
    
    // Messages envoyés = lus immédiatement
    if (newMessage.isMe) {
      final updatedMessage = newMessage.copyWith(isRead: true);
      _addMessageToList(conversationId, updatedMessage);
    } else {
      _addMessageToList(conversationId, newMessage);
    }
    
    notifyListeners();
  }

  // Envoi de message
  Future<void> sendMessage(int conversationId, String text) async {
    // 1. Appel API
    final response = await _chatService.sendMessage(conversationId, text);
    final newMessage = ChatMessage.fromJson(messageData, currentUserId);
    
    // 2. Ajout local avec statut lu
    final readMessage = newMessage.copyWith(isRead: true);
    _addMessageToList(conversationId, readMessage);
    
    notifyListeners();
  }

  // Marquer comme lu (local + API)
  Future<void> markAsRead(int conversationId) async {
    await _chatService.markAsRead(conversationId);
    
    // Mise à jour locale de tous les messages
    if (_messagesByConversation.containsKey(conversationId)) {
      final messages = _messagesByConversation[conversationId]!;
      _messagesByConversation[conversationId] = messages
          .map((msg) => msg.copyWith(isRead: true))
          .toList();
    }
    
    notifyListeners();
  }
}
```

### 5. Vue Chat

#### `lib/screens/chat_detail_screen.dart`
```dart
class ChatDetailScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Écouter les changements pour auto-scroll
    _chatProvider.addListener(_onMessagesChanged);
    
    if (_conversationId != null) {
      _chatProvider.loadMessages(_conversationId!).then((_) {
        // Auto-scroll après chargement
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      });
    }
  }

  void _onMessagesChanged() {
    // Auto-scroll quand nouveau message
    if (_conversationId != null) {
      final messages = _chatProvider.getMessages(_conversationId!);
      if (messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return Row(
      children: [
        Text(timeStr),
        if (message.isMe) ...[
          // Flèche simple grise si envoyé, double bleue si lu
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 16,
            color: message.isRead ? Color(0xFF0084FF) : Color(0xFF9E9E9E),
          ),
        ],
      ],
    );
  }
}
```

---

## 🔄 Workflow Complet

### 1. Envoi de Message
```
Flutter App
    ↓ [POST] /api/conversations/{id}/messages
Laravel Controller (ChatController@sendMessage)
    ↓ Crée Message en BDD
    ↓ broadcast(new NewChatMessage())
Laravel Broadcasting System
    ↓ Envoie à Pusher
Pusher WebSocket Service
    ↓ Distribue aux clients abonnés
Flutter Apps (tous les devices)
    ↓ WebSocketService.onEvent()
    ↓ ChatProvider._onNewMessage()
    ↓ UI update + auto-scroll
```

### 2. Réception de Message
```
Flutter App (destinataire)
    ↓ Écoute sur 'private-conversation.{id}'
Pusher → Event 'new.message'
    ↓ WebSocketService.onEvent()
    ↓ ChatProvider._onNewMessage()
    ↓ Ajout message local
    ↓ notifyListeners()
    ↓ UI update + auto-scroll
```

### 3. Marquer comme Lu
```
Flutter App (quand ouvre conversation)
    ↓ ChatProvider.loadMessages()
    ↓ markAsRead() API
Laravel Backend
    ↓ UPDATE messages SET is_read = true
    ↓ UPDATE conversations SET unread_count = 0
Flutter App (local)
    ↓ Met à jour tous les messages isRead = true
    ↓ UI update (flèches bleues)
```

---

## 🐛 Problèmes Résolus

### 1. **Backend ne broadcastait pas**
- **Cause** : `config/broadcasting.php` manquant
- **Solution** : Créer le fichier avec configuration Pusher
- **Commande** : `php artisan config:clear`

### 2. **Messages non reçus en temps réel**
- **Cause** : Mauvais nom d'événement ou canal
- **Solution** : `broadcastAs('new.message')` et `PrivateChannel('conversation.{id}')`

### 3. **Auto-scroll manuel**
- **Cause** : Pas de listener sur les changements de messages
- **Solution** : `ChatProvider.addListener(_onMessagesChanged)`

### 4. **Statut de lecture incorrect**
- **Cause** : Pas de champ `is_read` dans le modèle Flutter
- **Solution** : Ajouter `isRead` + mise à jour locale dans `markAsRead()`

### 5. **Flèches toujours bleues**
- **Cause** : Pas de gestion du statut de lecture
- **Solution** : `Icons.done` (grise) si envoyé, `Icons.done_all` (bleue) si lu

---

## 📝 Checklist de Déploiement

### Backend
- [ ] `.env` configuré avec clés Pusher
- [ ] `config/broadcasting.php` présent
- [ ] `php artisan config:clear` exécuté
- [ ] Routes broadcasting auth présentes
- [ ] `BROADCAST_DRIVER=pusher` activé

### Frontend
- [ ] Clés Pusher configurées dans WebSocketService
- [ ] Models avec champ `isRead`
- [ ] Auto-scroll implémenté
- [ ] Listener pour messages temps réel
- [ ] Gestion des flèches de statut

### Tests
- [ ] Envoi message → apparition instantanée sur autres devices
- [ ] Auto-scroll fonctionnel
- [ ] Flèches : grise → bleue
- [ ] Marquage comme lu quand on ouvre conversation

---

## 🔍 Debugging Commands

### Backend
```bash
# Vérifier config broadcasting
php artisan config:cache
php artisan config:clear

# Logs Laravel
tail -f storage/logs/laravel.log

# Vérifier Pusher
php artisan tinker
>>> broadcast(new NewChatMessage($conv, $msg, $user));
```

### Frontend
```dart
// Activer logs WebSocket
WebSocketService.onEvent = (event) {
  print('Event: ${event.eventName} on ${event.channelName}');
  print('Data: ${event.data}');
};
```

### Pusher Dashboard
- Vérifier les connexions actives
- Monitorer les événements envoyés/reçus
- Debug des erreurs d'authentification

---

**💡 Le workflow est maintenant complètement opérationnel avec un chat temps réel fiable !**
