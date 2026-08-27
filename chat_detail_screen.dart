import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String myUid;
  final ChatUser otherUser;

  const ChatDetailScreen({
    super.key,
    required this.myUid,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _storageService = StorageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;

  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = ChatConversation.buildId(widget.myUid, widget.otherUser.uid);
    _chatService.markConversationRead(_chatId, widget.myUid);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _chatService.sendMessage(
      myUid: widget.myUid,
      otherUid: widget.otherUser.uid,
      text: text,
    );
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    await _sendImageFile(File(picked.path));
  }

  Future<void> _captureAndSendImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    await _sendImageFile(File(picked.path));
  }

  Future<void> _sendImageFile(File file) async {
    setState(() => _sending = true);
    try {
      final url = await _storageService.uploadChatImage(_chatId, file);
      await _chatService.sendMessage(
        myUid: widget.myUid,
        otherUid: widget.otherUser.uid,
        text: '',
        type: MessageType.image,
        mediaUrl: url,
        fileName: file.uri.pathSegments.last,
        fileSize: await file.length(),
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Gagal mengirim gambar: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'txt', 'zip', 'rar', 'mp3', 'mp4',
      ],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    setState(() => _sending = true);
    try {
      final url = await _storageService.uploadChatFile(_chatId, file, fileName);
      await _chatService.sendMessage(
        myUid: widget.myUid,
        otherUid: widget.otherUser.uid,
        text: '',
        type: MessageType.file,
        mediaUrl: url,
        fileName: fileName,
        fileSize: await file.length(),
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Gagal mengirim berkas: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _captureAndSendImage();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insert_drive_file, color: AppColors.primary),
              title: const Text('Dokumen (PDF, dll)'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              photoUrl: widget.otherUser.photoUrl,
              initials: widget.otherUser.initials,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.otherUser.nickname,
                      style: const TextStyle(fontSize: 16)),
                  Text(
                    widget.otherUser.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.chatBg,
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.messagesFor(_chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Mulai percakapan Anda 👋',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    );
                  }
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return MessageBubble(
                        message: msg,
                        isMe: msg.senderId == widget.myUid,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.primary),
              onPressed: _sending ? null : _showAttachSheet,
            ),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: AppColors.accent,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sending ? null : _sendText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
