class ChatUser {
  final String uid;
  final String email;
  final String nickname;
  final String photoUrl;
  final String about;
  final DateTime? lastSeen;
  final bool isOnline;

  ChatUser({
    required this.uid,
    required this.email,
    required this.nickname,
    this.photoUrl = '',
    this.about = 'Hai, saya menggunakan ChatMate!',
    this.lastSeen,
    this.isOnline = false,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map, String uid) {
    return ChatUser(
      uid: uid,
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      about: map['about'] ?? 'Hai, saya menggunakan ChatMate!',
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'about': about,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'nicknameLower': nickname.toLowerCase(),
      'emailLower': email.toLowerCase(),
    };
  }

  String get initials {
    final parts = nickname.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
