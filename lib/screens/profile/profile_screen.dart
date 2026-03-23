import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/loading_indicator.dart';

final _profileProvider = FutureProvider.autoDispose<UserModel>((ref) {
  return ref.read(apiServiceProvider).getProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (user) => _ProfileContent(user: user),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => _uploadAvatar(context, ref),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          _initials(user.name ?? ''),
                          style: const TextStyle(fontSize: 28),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 16),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Имя'),
          subtitle: Text(user.name ?? ''),
          onTap: () => _editField(
            context,
            ref,
            title: 'Имя',
            initialValue: user.name ?? '',
            onSave: (v) =>
                ref.read(apiServiceProvider).updateProfile({'name': v}),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Местоположение'),
          subtitle: Text(user.location ?? ''),
          onTap: () => _editField(
            context,
            ref,
            title: 'Местоположение',
            initialValue: user.location ?? '',
            onSave: (v) =>
                ref.read(apiServiceProvider).updateProfile({'location': v}),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('Уровень опыта'),
          subtitle: Text(user.experienceLevel ?? ''),
          onTap: () =>
              _editExperienceLevel(context, ref, user.experienceLevel ?? ''),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.meeting_room),
          title: const Text('Мои комнаты'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/rooms'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Выйти', style: TextStyle(color: Colors.red)),
          onTap: () => ref.read(authServiceProvider).signOut(),
        ),
      ],
    );
  }

  Future<void> _uploadAvatar(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      await ref.read(apiServiceProvider).uploadAvatar(file.path);
      ref.invalidate(_profileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватарка обновлена')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _editField(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String initialValue,
    required Future<UserModel> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Изменить $title'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await onSave(controller.text);
                ref.invalidate(_profileProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _editExperienceLevel(
      BuildContext context, WidgetRef ref, String current) async {
    String selected = current;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Уровень опыта'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => setState(() => selected = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['beginner', 'intermediate', 'experienced']
                  .map((level) => RadioListTile<String>(
                        title: Text(level),
                        value: level,
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(apiServiceProvider)
                      .updateProfile({'experience_level': selected});
                  ref.invalidate(_profileProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
