import 'package:flutter/material.dart';
import '../services/chat_storage_service.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.time,
    this.read = false,
    this.edited = false,
    this.recalled = false,
    this.reaction,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String content;
  final DateTime time;
  bool read;
  bool edited;
  bool recalled;
  String? reaction;
}

class Conversation {
  Conversation({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
  });

  final String id; // key: smallerId-biggerId
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final List<ChatMessage> messages = [];
}

class ChatProvider extends ChangeNotifier {
  String? _currentUserId;

  final List<Conversation> _conversations = [];

  bool isOpen = false;
  String? targetUserId;

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  int get unreadCount {
    final me = _currentUserId;
    if (me == null) return 0;
    return _conversations.fold<int>(0, (sum, c) {
      return sum +
          c.messages.where((m) => m.toUserId == me && m.fromUserId != me && !m.read).length;
    });
  }

  // Get unread count for specific user - uses ChatStorageService
  int getUnreadCount(String userId) {
    return ChatStorageService.unreadCountForUser(userId);
  }

  void setCurrentUser({required String userId, String? name, String? avatar}) {
    _currentUserId = userId;
    notifyListeners();
  }

  void openChatList() {
    isOpen = true;
    targetUserId = null;
    notifyListeners();
  }

  void openChatWith(String partnerId, {String? partnerName, String? avatar}) {
    targetUserId = partnerId;
    isOpen = true;
    _ensureConversation(partnerId, partnerName ?? 'Người dùng', avatar);
    notifyListeners();
  }

  void toggleChat() {
    isOpen = !isOpen;
    notifyListeners();
  }

  void closeChat() {
    isOpen = false;
    targetUserId = null;
    notifyListeners();
  }

  Conversation _ensureConversation(String partnerId, String partnerName, String? avatar) {
    final selfId = _currentUserId ?? 'current';
    final convId = selfId.compareTo(partnerId) < 0 ? '$selfId-$partnerId' : '$partnerId-$selfId';
    final existing = _conversations.where((c) => c.id == convId).cast<Conversation?>().firstWhere(
          (c) => c != null,
          orElse: () => null,
        );
    if (existing != null) return existing;
    final conv = Conversation(
      id: convId,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerAvatar: avatar,
    );
    _conversations.add(conv);
    return conv;
  }

  void sendMessage(String partnerId, String text, {String? partnerName, String? avatar}) {
    if (_currentUserId == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conv = _ensureConversation(partnerId, partnerName ?? 'Người dùng', avatar);
    conv.messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromUserId: _currentUserId!,
      toUserId: partnerId,
      content: trimmed,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  void editMessage(String messageId, String newText) {
    final me = _currentUserId;
    if (me == null) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    for (final c in _conversations) {
      for (var i = 0; i < c.messages.length; i++) {
        final m = c.messages[i];
        if (m.id == messageId && m.fromUserId == me && !m.recalled) {
          c.messages[i] = ChatMessage(
            id: m.id,
            fromUserId: m.fromUserId,
            toUserId: m.toUserId,
            content: trimmed,
            time: m.time,
            read: m.read,
            edited: true,
            recalled: m.recalled,
            reaction: m.reaction,
          );
          notifyListeners();
          return;
        }
      }
    }
  }

  void recallMessage(String messageId) {
    final me = _currentUserId;
    if (me == null) return;
    for (final c in _conversations) {
      for (var i = 0; i < c.messages.length; i++) {
        final m = c.messages[i];
        if (m.id == messageId && m.fromUserId == me && !m.recalled) {
          c.messages[i] = ChatMessage(
            id: m.id,
            fromUserId: m.fromUserId,
            toUserId: m.toUserId,
            content: 'Tin nhắn đã được thu hồi',
            time: m.time,
            read: m.read,
            edited: m.edited,
            recalled: true,
            reaction: null,
          );
          notifyListeners();
          return;
        }
      }
    }
  }

  void setMessageReaction(String messageId, String? reaction) {
    for (final c in _conversations) {
      for (final m in c.messages) {
        if (m.id == messageId) {
          m.reaction = reaction;
          notifyListeners();
          return;
        }
      }
    }
  }

  void markConversationRead(String convId) {
    final me = _currentUserId;
    if (me == null) return;
    final conv = _conversations.where((c) => c.id == convId).cast<Conversation?>().firstWhere(
          (c) => c != null,
          orElse: () => null,
        );
    if (conv == null) return;
    for (final m in conv.messages) {
      if (m.toUserId == me) m.read = true;
    }
    notifyListeners();
  }
}
