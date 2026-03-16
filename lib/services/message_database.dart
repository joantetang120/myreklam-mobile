import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:myreklam/models/chat_message.dart';

class MessageDatabase {
  static final MessageDatabase instance = MessageDatabase._init();
  static Database? _database;

  MessageDatabase._init() {
    _initializePlatform();
  }

  void _initializePlatform() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('messages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        conversation_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        sender_name TEXT,
        sender_avatar TEXT,
        attachments TEXT,
        is_pending INTEGER NOT NULL DEFAULT 0,
        is_edited INTEGER NOT NULL DEFAULT 0,
        edited_at TEXT,
        deleted_for_everyone INTEGER NOT NULL DEFAULT 0,
        deleted_for_sender INTEGER NOT NULL DEFAULT 0,
        deleted_for_receiver INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_conversation ON messages(conversation_id)
    ''');

    await _createConversationsTable(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN is_edited INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE messages ADD COLUMN edited_at TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN deleted_for_everyone INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE messages ADD COLUMN deleted_for_sender INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE messages ADD COLUMN deleted_for_receiver INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future _createConversationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        partner_id INTEGER,
        last_message TEXT,
        last_message_time TEXT,
        unread_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> saveMessage(ChatMessage message, int currentUserId) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'text': message.text,
        'created_at': message.createdAt.toIso8601String(),
        'is_read': message.isRead ? 1 : 0,
        'sender_name': message.senderName,
        'sender_avatar': message.senderAvatar,
        'attachments': message.attachments != null
            ? _encodeAttachments(message.attachments!)
            : null,
        'is_pending': 0,
        'is_edited': message.isEdited ? 1 : 0,
        'edited_at': message.editedAt?.toIso8601String(),
        'deleted_for_everyone': message.deletedForEveryone ? 1 : 0,
        'deleted_for_sender': message.deletedForSender ? 1 : 0,
        'deleted_for_receiver': message.deletedForReceiver ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveMessages(
    List<ChatMessage> messages,
    int conversationId,
    int currentUserId,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      batch.insert(
        'messages',
        {
          'id': message.id,
          'conversation_id': conversationId,
          'sender_id': message.senderId,
          'text': message.text,
          'created_at': message.createdAt.toIso8601String(),
          'is_read': message.isRead ? 1 : 0,
          'sender_name': message.senderName,
          'sender_avatar': message.senderAvatar,
          'attachments': message.attachments != null
              ? _encodeAttachments(message.attachments!)
              : null,
          'is_pending': 0,
          'is_edited': message.isEdited ? 1 : 0,
          'edited_at': message.editedAt?.toIso8601String(),
          'deleted_for_everyone': message.deletedForEveryone ? 1 : 0,
          'deleted_for_sender': message.deletedForSender ? 1 : 0,
          'deleted_for_receiver': message.deletedForReceiver ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ChatMessage>> getMessages(
    int conversationId,
    int currentUserId,
  ) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'conversation_id = ? AND is_pending = 0',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return result.map((json) => _messageFromMap(json, currentUserId)).toList();
  }

  Future<void> savePendingMessage(
    int conversationId,
    String text,
    int currentUserId,
    Map<String, dynamic>? attachments,
  ) async {
    final db = await database;
    await db.insert('messages', {
      'id': DateTime.now().millisecondsSinceEpoch,
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': 0,
      'attachments':
          attachments != null ? _encodeAttachments(attachments) : null,
      'is_pending': 1,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingMessages(
    int conversationId,
  ) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ? AND is_pending = 1',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> deletePendingMessage(int tempId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ? AND is_pending = 1',
      whereArgs: [tempId],
    );
  }

  Future<void> clearConversationMessages(int conversationId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map, int currentUserId) {
    return ChatMessage(
      id: map['id'] as int,
      conversationId: map['conversation_id'] as int,
      senderId: map['sender_id'] as int,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isMe: (map['sender_id'] as int) == currentUserId,
      isRead: (map['is_read'] as int) == 1,
      senderName: map['sender_name'] as String?,
      senderAvatar: map['sender_avatar'] as String?,
      attachments: map['attachments'] != null
          ? _decodeAttachments(map['attachments'] as String)
          : null,
      isEdited: (map['is_edited'] as int?) == 1,
      editedAt: map['edited_at'] != null
          ? DateTime.tryParse(map['edited_at'] as String)
          : null,
      deletedForEveryone: (map['deleted_for_everyone'] as int?) == 1,
      deletedForSender: (map['deleted_for_sender'] as int?) == 1,
      deletedForReceiver: (map['deleted_for_receiver'] as int?) == 1,
    );
  }

  String _encodeAttachments(Map<String, dynamic> attachments) {
    return attachments.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodeAttachments(String encoded) {
    final map = <String, dynamic>{};
    for (final pair in encoded.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
