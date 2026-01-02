import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatRoom {
  final String id;
  final String userId1;
  final String userId2;
  final String user1Name;
  final String user2Name;
  final String? user1Avatar;
  final String? user2Avatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.user1Name,
    required this.user2Name,
    this.user1Avatar,
    this.user2Avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}

class ChatStorageService {
  static late SharedPreferences _prefs;
  static const String _messagesKey = 'chat_messages_key';
  static const String _roomsKey = 'chat_rooms_key';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get chat room ID for two users
  static String getChatRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  /// Save all messages
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    final jsonList = messages.map((m) => _messageToJson(m)).toList();
    await _prefs.setString(_messagesKey, jsonEncode(jsonList));
  }

  /// Load all messages
  static Future<List<ChatMessage>> loadMessages() async {
    final jsonStr = _prefs.getString(_messagesKey);
    if (jsonStr == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((json) => _messageFromJson(json)).toList();
  }

  /// Add a new message
  static Future<void> addMessage(ChatMessage message) async {
    final messages = await loadMessages();
    messages.add(message);
    await saveMessages(messages);
    await _updateChatRoom(message);
  }

  /// Get messages for a chat room
  static Future<List<ChatMessage>> getMessagesForRoom(String chatRoomId) async {
    final all = await loadMessages();
    return all.where((m) => m.chatRoomId == chatRoomId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Save all chat rooms
  static Future<void> saveRooms(List<ChatRoom> rooms) async {
    final jsonList = rooms.map((r) => _roomToJson(r)).toList();
    await _prefs.setString(_roomsKey, jsonEncode(jsonList));
  }

  /// Load all chat rooms
  static Future<List<ChatRoom>> loadRooms() async {
    final jsonStr = _prefs.getString(_roomsKey);
    if (jsonStr == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((json) => _roomFromJson(json)).toList();
  }

  /// Count unread messages for a user (messages from others, unread)
  static int unreadCountForUser(String userId) {
    final jsonStr = _prefs.getString(_messagesKey);
    if (jsonStr == null) return 0;
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    int count = 0;
    for (final item in jsonList) {
      final json = item as Map<String, dynamic>;
      if (json['receiverId'] == userId && json['senderId'] != userId && json['isRead'] == false) {
        count++;
      }
    }
    return count;
  }

  /// Get chat rooms for a user
  static Future<List<ChatRoom>> getRoomsForUser(String userId) async {
    final all = await loadRooms();
    final filtered = all.where((r) => r.userId1 == userId || r.userId2 == userId).map((room) {
      final unread = _unreadForRoom(room.id, userId);
      return ChatRoom(
        id: room.id,
        userId1: room.userId1,
        userId2: room.userId2,
        user1Name: room.user1Name,
        user2Name: room.user2Name,
        user1Avatar: room.user1Avatar,
        user2Avatar: room.user2Avatar,
        lastMessage: room.lastMessage,
        lastMessageTime: room.lastMessageTime,
        unreadCount: unread,
      );
    }).toList();

    filtered.sort((a, b) {
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });

    return filtered;
  }

  /// Create or get existing chat room
  static Future<ChatRoom> getOrCreateRoom({
    required String userId1,
    required String userId2,
    required String user1Name,
    required String user2Name,
    String? user1Avatar,
    String? user2Avatar,
  }) async {
    final chatRoomId = getChatRoomId(userId1, userId2);
    final rooms = await loadRooms();
    final existing = rooms.firstWhere(
      (r) => r.id == chatRoomId,
      orElse: () => ChatRoom(
        id: chatRoomId,
        userId1: userId1,
        userId2: userId2,
        user1Name: user1Name,
        user2Name: user2Name,
        user1Avatar: user1Avatar,
        user2Avatar: user2Avatar,
      ),
    );
    
    if (!rooms.any((r) => r.id == chatRoomId)) {
      rooms.add(existing);
      await saveRooms(rooms);
    }
    
    return existing;
  }

  /// Update chat room with latest message
  static Future<void> _updateChatRoom(ChatMessage message) async {
    final rooms = await loadRooms();
    final index = rooms.indexWhere((r) => r.id == message.chatRoomId);
    
    if (index != -1) {
      final room = rooms[index];
      final lastMessageRoom = ChatRoom(
        id: room.id,
        userId1: room.userId1,
        userId2: room.userId2,
        user1Name: room.user1Name,
        user2Name: room.user2Name,
        user1Avatar: room.user1Avatar,
        user2Avatar: room.user2Avatar,
        lastMessage: message.message,
        lastMessageTime: message.timestamp,
        // unreadCount recomputed when fetching rooms per user
        unreadCount: room.unreadCount,
      );
      rooms[index] = lastMessageRoom;
      await saveRooms(rooms);
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final messages = await loadMessages();
    bool updated = false;
    
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].chatRoomId == chatRoomId && 
          messages[i].senderId != userId && 
          !messages[i].isRead) {
        messages[i] = ChatMessage(
          id: messages[i].id,
          chatRoomId: messages[i].chatRoomId,
          senderId: messages[i].senderId,
          senderName: messages[i].senderName,
          senderAvatar: messages[i].senderAvatar,
          receiverId: messages[i].receiverId,
          message: messages[i].message,
          timestamp: messages[i].timestamp,
          isRead: true,
        );
        updated = true;
      }
    }
    
    if (updated) {
      await saveMessages(messages);
      await _resetUnreadCount(chatRoomId);
    }
  }

  /// Reset unread count for a room
  static Future<void> _resetUnreadCount(String chatRoomId) async {
    final rooms = await loadRooms();
    final index = rooms.indexWhere((r) => r.id == chatRoomId);
    
    if (index != -1) {
      final room = rooms[index];
      rooms[index] = ChatRoom(
        id: room.id,
        userId1: room.userId1,
        userId2: room.userId2,
        user1Name: room.user1Name,
        user2Name: room.user2Name,
        user1Avatar: room.user1Avatar,
        user2Avatar: room.user2Avatar,
        lastMessage: room.lastMessage,
        lastMessageTime: room.lastMessageTime,
        unreadCount: 0,
      );
      await saveRooms(rooms);
    }
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'chatRoomId': message.chatRoomId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'senderAvatar': message.senderAvatar,
      'receiverId': message.receiverId,
      'message': message.message,
      'timestamp': message.timestamp.toIso8601String(),
      'isRead': message.isRead,
    };
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatRoomId: json['chatRoomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      receiverId: json['receiverId'] ?? '',
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  static Map<String, dynamic> _roomToJson(ChatRoom room) {
    return {
      'id': room.id,
      'userId1': room.userId1,
      'userId2': room.userId2,
      'user1Name': room.user1Name,
      'user2Name': room.user2Name,
      'user1Avatar': room.user1Avatar,
      'user2Avatar': room.user2Avatar,
      'lastMessage': room.lastMessage,
      'lastMessageTime': room.lastMessageTime?.toIso8601String(),
      'unreadCount': room.unreadCount,
    };
  }

  static ChatRoom _roomFromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      userId1: json['userId1'],
      userId2: json['userId2'],
      user1Name: json['user1Name'],
      user2Name: json['user2Name'],
      user1Avatar: json['user1Avatar'],
      user2Avatar: json['user2Avatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  static int _unreadForRoom(String roomId, String userId) {
    final messages = _prefs.getString(_messagesKey);
    if (messages == null) return 0;
    final List<dynamic> list = jsonDecode(messages);
    int count = 0;
    for (final item in list) {
      final json = item as Map<String, dynamic>;
      if (json['chatRoomId'] == roomId && json['receiverId'] == userId && json['senderId'] != userId && (json['isRead'] == false)) {
        count++;
      }
    }
    return count;
  }
}
