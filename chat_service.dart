import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all users except the current one, so a user can start a
  /// conversation with any other registered account (e.g. Ahmad Riko can
  /// find and chat with Amelia Citra and vice versa).
  Stream<List<ChatUser>> allUsers(String myUid) {
    return _db.collection('users').snapshots().map((snap) => snap.docs
        .where((d) => d.id != myUid)
        .map((d) => ChatUser.fromMap(d.data(), d.id))
        .toList());
  }

  /// Stream of the current user's conversation list, ordered by most recent.
  Stream<List<ChatConversation>> myConversations(String myUid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatConversation.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ChatMessage>> messagesFor(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  Future<void> sendMessage({
    required String myUid,
    required String otherUid,
    required String text,
    MessageType type = MessageType.text,
    String mediaUrl = '',
    String fileName = '',
    int fileSize = 0,
  }) async {
    final chatId = ChatConversation.buildId(myUid, otherUid);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final message = ChatMessage(
      id: msgRef.id,
      senderId: myUid,
      receiverId: otherUid,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      sentAt: DateTime.now(),
      isDelivered: true,
    );

    final previewText = switch (type) {
      MessageType.text => text,
      MessageType.image => '📷 Foto',
      MessageType.video => '🎥 Video',
      MessageType.file => '📎 $fileName',
    };

    final batch = _db.batch();
    batch.set(msgRef, message.toMap());
    batch.set(
      chatRef,
      {
        'participants': [myUid, otherUid],
        'lastMessage': previewText,
        'lastMessageType': type.name,
        'lastMessageTime': message.sentAt.millisecondsSinceEpoch,
        'lastSenderId': myUid,
        'unreadCount.$otherUid': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markConversationRead(String chatId, String myUid) async {
    await _db.collection('chats').doc(chatId).set(
      {
        'unreadCount.$myUid': 0,
      },
      SetOptions(merge: true),
    );

    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: myUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
