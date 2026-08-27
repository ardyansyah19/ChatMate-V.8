enum MessageType { text, image, file, video }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final String mediaUrl;
  final String fileName;
  final int fileSize;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.type = MessageType.text,
    this.mediaUrl = '',
    this.fileName = '',
    this.fileSize = 0,
    required this.sentAt,
    this.isRead = false,
    this.isDelivered = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
          map['sentAt'] ?? DateTime.now().millisecondsSinceEpoch),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDelivered': isDelivered,
    };
  }
}
