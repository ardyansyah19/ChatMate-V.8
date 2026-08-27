import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String uid;
  const SettingsScreen({super.key, required this.uid});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storageService.uploadProfilePhoto(
        widget.uid,
        File(picked.path),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'photoUrl': url});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editNickname(String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nickname'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nickname'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({'nickname': result, 'nicknameLower': result.toLowerCase()});
  }

  Future<void> _editAbout(String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Info'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Info'),
          autofocus: true,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({'about': result});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: StreamBuilder<ChatUser?>(
        stream: _authService.userStream(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          return ListView(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    UserAvatar(
                      photoUrl: user.photoUrl,
                      initials: user.initials,
                      radius: 60,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _changePhoto,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accent,
                          child: _uploadingPhoto
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SettingsTile(
                icon: Icons.person_outline,
                label: 'Nickname',
                value: user.nickname,
                onTap: () => _editNickname(user.nickname),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'Info',
                value: user.about,
                onTap: () => _editAbout(user.about),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      trailing: onTap != null ? const Icon(Icons.edit, size: 18) : null,
      onTap: onTap,
    );
  }
}
