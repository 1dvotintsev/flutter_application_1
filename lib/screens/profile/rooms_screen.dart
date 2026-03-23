import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/room.dart';
import '../../widgets/loading_indicator.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Комнаты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRoomDialog(context, ref, null),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (rooms) => rooms.isEmpty
            ? const Center(child: Text('Добавьте комнату'))
            : ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return ListTile(
                    title: Text(room.name ?? ''),
                    subtitle: Text(
                      '${_lightLabel(room.lightLevel ?? '')} \u2022 Окна: ${_directionLabel(room.windowDirection ?? '')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showRoomDialog(context, ref, room),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _confirmDelete(context, ref, room),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _lightLabel(String level) {
    switch (level) {
      case 'low':
        return 'Низкая';
      case 'medium':
        return 'Средняя';
      case 'bright':
        return 'Высокая';
      default:
        return level;
    }
  }

  String _directionLabel(String dir) {
    switch (dir) {
      case 'north':
        return 'Север';
      case 'south':
        return 'Юг';
      case 'east':
        return 'Восток';
      case 'west':
        return 'Запад';
      case 'none':
        return 'Нет окна';
      default:
        return dir;
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить комнату?'),
        content: Text('Удалить "${room.name ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(apiServiceProvider).deleteRoom(room.id);
        ref.invalidate(roomsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Future<void> _showRoomDialog(
      BuildContext context, WidgetRef ref, Room? room) async {
    final nameController = TextEditingController(text: room?.name ?? '');
    String lightLevel = room?.lightLevel ?? 'medium';
    String windowDirection = room?.windowDirection ?? 'none';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(room == null ? 'Добавить комнату' : 'Изменить комнату'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: lightLevel,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Низкая')),
                  DropdownMenuItem(value: 'medium', child: Text('Средняя')),
                  DropdownMenuItem(value: 'bright', child: Text('Высокая')),
                ],
                onChanged: (v) => setState(() => lightLevel = v!),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: windowDirection,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'north', child: Text('Север')),
                  DropdownMenuItem(value: 'south', child: Text('Юг')),
                  DropdownMenuItem(value: 'east', child: Text('Восток')),
                  DropdownMenuItem(value: 'west', child: Text('Запад')),
                  DropdownMenuItem(value: 'none', child: Text('Нет окна')),
                ],
                onChanged: (v) => setState(() => windowDirection = v!),
              ),
            ],
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
                  final data = {
                    'name': nameController.text,
                    'light_level': lightLevel,
                    'window_direction': windowDirection,
                  };
                  if (room == null) {
                    await ref.read(apiServiceProvider).createRoom(data);
                  } else {
                    await ref
                        .read(apiServiceProvider)
                        .updateRoom(room.id, data);
                  }
                  ref.invalidate(roomsProvider);
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
