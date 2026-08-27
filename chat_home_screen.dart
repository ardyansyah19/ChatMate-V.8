import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../settings/settings_screen.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

class ChatHomeScreen extends StatelessWidget {
  final String uid;
  const ChatHomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatMate'),
        actions: [
          StreamBuilder<ChatUser?>(
            stream: authService.userStream(uid),
            builder: (context, snapshot) {
              final me = snapshot.data;
              return IconButton(
                tooltip: 'Pengaturan',
                icon: UserAvatar(
                  photoUrl: me?.photoUrl ?? '',
                  initials: me?.initials ?? '?',
                  radius: 16,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen(uid: uid)),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: chatService.myConversations(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return _EmptyState(uid: uid);
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 78, color: AppColors.divider),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUid =
                  chat.participants.firstWhere((p) => p != uid, orElse: () => '');
              return StreamBuilder<ChatUser?>(
                stream: authService.userStream(otherUid),
                builder: (context, userSnap) {
                  final other = userSnap.data;
                  final unread = chat.unreadCount[uid] ?? 0;
                  return ListTile(
                    leading: UserAvatar(
                      photoUrl: other?.photoUrl ?? '',
                      initials: other?.initials ?? '?',
                      radius: 26,
                    ),
                    title: Text(
                      other?.nickname ?? 'Pengguna',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontWeight:
                            unread > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: unread > 0
                                ? AppColors.accent
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (unread > 0)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      if (other == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            myUid: uid,
                            otherUser: other,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewChatScreen(myUid: uid)),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    if (isToday) return DateFormat.Hm().format(time);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == time.year &&
        yesterday.month == time.month &&
        yesterday.day == time.day;
    if (isYesterday) return 'Kemarin';
    return DateFormat('dd/MM/yy').format(time);
  }
}

class _EmptyState extends StatelessWidget {
  final String uid;
  const _EmptyState({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 72, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text(
              'Belum ada percakapan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk tombol chat di bawah untuk mulai mengobrol dengan pengguna lain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
