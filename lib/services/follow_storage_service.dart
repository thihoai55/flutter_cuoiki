import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FollowRelationship {
  final String followerId; // Người theo dõi
  final String followedId; // Người được theo dõi
  final DateTime timestamp;

  FollowRelationship({
    required this.followerId,
    required this.followedId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'followerId': followerId,
      'followedId': followedId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FollowRelationship.fromJson(Map<String, dynamic> json) {
    return FollowRelationship(
      followerId: json['followerId'],
      followedId: json['followedId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class FollowStorageService {
  static late SharedPreferences _prefs;
  static const String _followsKey = 'follow_relationships_key';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveRelationships(List<FollowRelationship> relationships) async {
    final jsonList = relationships.map((r) => r.toJson()).toList();
    await _prefs.setString(_followsKey, jsonEncode(jsonList));
  }

  static Future<List<FollowRelationship>> loadRelationships() async {
    final jsonStr = _prefs.getString(_followsKey);
    if (jsonStr == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((json) => FollowRelationship.fromJson(json)).toList();
  }

  static Future<void> follow(String followerId, String followedId) async {
    final relationships = await loadRelationships();
    // Check if already following
    if (relationships.any((r) => r.followerId == followerId && r.followedId == followedId)) {
      return;
    }
    relationships.add(FollowRelationship(
      followerId: followerId,
      followedId: followedId,
      timestamp: DateTime.now(),
    ));
    await saveRelationships(relationships);
  }

  static Future<void> unfollow(String followerId, String followedId) async {
    final relationships = await loadRelationships();
    relationships.removeWhere((r) => r.followerId == followerId && r.followedId == followedId);
    await saveRelationships(relationships);
  }

  static Future<bool> isFollowing(String followerId, String followedId) async {
    final relationships = await loadRelationships();
    return relationships.any((r) => r.followerId == followerId && r.followedId == followedId);
  }

  static Future<List<String>> getFollowers(String userId) async {
    final relationships = await loadRelationships();
    return relationships
        .where((r) => r.followedId == userId)
        .map((r) => r.followerId)
        .toList();
  }

  static Future<List<String>> getFollowing(String userId) async {
    final relationships = await loadRelationships();
    return relationships
        .where((r) => r.followerId == userId)
        .map((r) => r.followedId)
        .toList();
  }
}
