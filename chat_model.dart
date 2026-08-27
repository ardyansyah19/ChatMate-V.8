class ChatConversation {
  final String id; // deterministic: sorted uid pair joined by "_"
  final List<String> participants;
  final String lastMessage;
  final String lastMessageType;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final Map<String, int> unreadCount;

  ChatConversation({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageType = 'text',
    required this.lastMessageTime,
    this.lastSenderId = '',
    this.unreadCount = const {},
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: map['lastMessageType'] ?? 'text',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
          map['lastMessageTime'] ?? DateTime.now().millisecondsSinceEpoch),
      lastSenderId: map['lastSenderId'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
    };
  }

  static String buildId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
