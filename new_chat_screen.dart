import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/user_avatar.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatelessWidget {
  final String myUid;
  const NewChatScreen({super.key, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Kontak')),
      body: StreamBuilder<List<ChatUser>>(
        stream: chatService.allUsers(myUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada pengguna lain yang terdaftar.\n'
                  'Minta teman Anda untuk mendaftar di ChatMate.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: UserAvatar(
                  photoUrl: user.photoUrl,
                  initials: user.initials,
                  radius: 24,
                ),
                title: Text(user.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(user.about,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        myUid: myUid,
                        otherUser: user,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
