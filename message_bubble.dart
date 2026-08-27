import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;
import '../models/message_model.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? AppColors.bubbleOut : AppColors.bubbleIn;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMe ? 12 : 2),
      bottomRight: Radius.circular(isMe ? 2 : 12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: message.type == MessageType.text
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : const EdgeInsets.all(6),
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _ImageContent(message: message, isMe: isMe);
      case MessageType.file:
        return _FileContent(message: message, isMe: isMe);
      case MessageType.video:
        return _FileContent(message: message, isMe: isMe);
      case MessageType.text:
        return _TextContent(message: message, isMe: isMe);
    }
  }
}

class _TextContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _TextContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message.text, style: const TextStyle(fontSize: 15.5)),
        const SizedBox(height: 2),
        _MetaRow(message: message, isMe: isMe),
      ],
    );
  }
}

class _ImageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _ImageContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _openFullImage(context, message.mediaUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl,
              width: 220,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 220,
                height: 220,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 220,
                height: 150,
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          child: _MetaRow(message: message, isMe: isMe),
        ),
      ],
    );
  }

  void _openFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _FileContent({required this.message, required this.isMe});

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  Future<void> _downloadAndOpen(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${message.fileName}';
      await dio.Dio().download(message.mediaUrl, savePath);
      await OpenFilex.open(savePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka berkas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _downloadAndOpen(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insert_drive_file,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        _formatSize(message.fileSize),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            _MetaRow(message: message, isMe: isMe),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MetaRow({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.Hm().format(message.sentAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 15,
            color: message.isRead ? Colors.blue : AppColors.textLight,
          ),
        ],
      ],
    );
  }
}
