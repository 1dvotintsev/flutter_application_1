import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/plants_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/care_event.dart';
import '../../models/care_schedule.dart';
import '../../models/room.dart';
import '../../models/species.dart';
import '../../widgets/loading_indicator.dart';

final _plantEventsProvider =
    FutureProvider.autoDispose.family<List<CareEvent>, int>((ref, plantId) {
  return ref.read(apiServiceProvider).getPlantEvents(plantId);
});

String _careTypeLabel(String careType) {
  switch (careType) {
    case 'water':
      return '\u{1F4A7} Полив';
    case 'fertilize':
      return '\u{1F331} Подкормка';
    case 'repot':
      return '\u{1FAB4} Пересадка';
    default:
      return careType;
  }
}

IconData _careTypeIcon(String careType) {
  switch (careType) {
    case 'water':
      return Icons.water_drop;
    case 'fertilize':
      return Icons.grass;
    case 'repot':
      return Icons.yard;
    default:
      return Icons.eco;
  }
}

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.parse(plantId);
    final plantAsync = ref.watch(plantDetailProvider(id));

    return plantAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingIndicator()),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('Ошибка: $e'))),
      data: (plant) {
        final eventsAsync = ref.watch(_plantEventsProvider(id));
        final species = plant.species;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const BackButton(color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      () {
                        final imageUrl = plant.photoUrl ?? plant.species?.imageUrl;
                        return imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.green[100],
                                child: const Icon(Icons.eco,
                                    size: 80, color: Colors.green),
                              );
                      }(),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: () =>
                                _pickAndUploadPhoto(context, ref, id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'species') {
                        context.push('/species/${plant.speciesId}');
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Удалить растение?'),
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
                        if (confirmed == true && context.mounted) {
                          try {
                            await ref
                                .read(apiServiceProvider)
                                .deletePlant(plant.id);
                            if (context.mounted) context.pop();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                          value: 'species', child: Text('О виде')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название и вид
                      Text(
                        plant.nickname ?? species?.commonName ?? 'Растение',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (species != null)
                        Text(
                          species.scientificName ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                        ),
                      const SizedBox(height: 12),

                      // Комната и горшок
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showChangeRoomDialog(
                                context, ref, id, plant.room?.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  plant.room?.name ?? 'Комната не назначена',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[700]),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                          if (plant.potType != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.local_florist_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              plant.potType!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Рекомендации по уходу (из species)
                      if (species != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Рекомендации',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                _RecommendationRow(
                                  icon: Icons.water_drop,
                                  iconColor: Colors.blue,
                                  label: 'Полив',
                                  value: species.waterIntervalDays != null
                                      ? 'каждые ${species.waterIntervalDays} дней'
                                      : '—',
                                ),
                                const SizedBox(height: 6),
                                _RecommendationRow(
                                  icon: Icons.wb_sunny,
                                  iconColor: Colors.amber,
                                  label: 'Свет',
                                  value: species.lightRequirement ?? '—',
                                ),
                                if (species.temperatureMin != null &&
                                    species.temperatureMax != null) ...[
                                  const SizedBox(height: 6),
                                  _RecommendationRow(
                                    icon: Icons.thermostat,
                                    iconColor: Colors.orange,
                                    label: 'Температура',
                                    value:
                                        '${species.temperatureMin}\u2013${species.temperatureMax} \u00B0C',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // График ухода
                      if (plant.schedules != null &&
                          plant.schedules!.isNotEmpty) ...[
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'График ухода',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              ...plant.schedules!.map((s) {
                                final rec =
                                    _speciesRecommendation(s, species);
                                final isCustom = rec != null &&
                                    s.intervalDays != null &&
                                    s.intervalDays != rec;
                                return ListTile(
                                  leading:
                                      Icon(_careTypeIcon(s.careType ?? '')),
                                  title:
                                      Text(_careTypeLabel(s.careType ?? '')),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (s.intervalDays != null)
                                        Row(children: [
                                          Text(
                                            isCustom
                                                ? 'каждые ${s.intervalDays} дн. (рек.: $rec)'
                                                : 'каждые ${s.intervalDays} дн.',
                                          ),
                                          if (isCustom) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[100],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text('изменено',
                                                  style:
                                                      TextStyle(fontSize: 10)),
                                            ),
                                          ],
                                        ]),
                                      if (s.nextDue != null)
                                        Text(
                                          'Следующий: ${DateFormat('dd.MM.yyyy').format(s.nextDue!)}',
                                        ),
                                    ],
                                  ),
                                  isThreeLine: s.intervalDays != null &&
                                      s.nextDue != null,
                                  onTap: () => _showEditIntervalDialog(
                                      context, ref, s, species, id),
                                  trailing: IconButton(
                                    icon: const Icon(
                                        Icons.check_circle_outline),
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(apiServiceProvider)
                                            .completeSchedule(s.id);
                                        ref.invalidate(
                                            plantDetailProvider(id));
                                        ref.invalidate(todayTasksProvider);
                                        ref.invalidate(
                                            upcomingSchedulesProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Готово!')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Ошибка: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Журнал ухода
                      const Divider(),
                      Row(
                        children: [
                          Text(
                            'Журнал ухода',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                _showAddEventDialog(context, ref, id),
                            child: const Text('+ Запись'),
                          ),
                        ],
                      ),
                      eventsAsync.when(
                        loading: () => const LoadingIndicator(),
                        error: (e, _) =>
                            Text('Ошибка загрузки журнала: $e'),
                        data: (events) => events.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('Записей пока нет'),
                              )
                            : Column(
                                children: events
                                    .map(
                                      (e) => ListTile(
                                        leading: Icon(
                                            _careTypeIcon(e.careType ?? '')),
                                        title: Text(
                                            _careTypeLabel(e.careType ?? '')),
                                        subtitle: Text(
                                          '${e.performedAt != null ? DateFormat('dd.MM.yyyy').format(e.performedAt!) : ''}'
                                          '${e.notes != null ? '\n${e.notes}' : ''}',
                                        ),
                                        isThreeLine: e.notes != null,
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int? _speciesRecommendation(CareSchedule s, Species? species) {
    if (species == null) return null;
    switch (s.careType) {
      case 'water':
        return species.waterIntervalDays;
      case 'fertilize':
        return species.fertilizeIntervalDays;
      case 'repot':
        return species.repotIntervalMonths != null
            ? species.repotIntervalMonths! * 30
            : null;
      default:
        return null;
    }
  }

  Future<void> _showEditIntervalDialog(
    BuildContext context,
    WidgetRef ref,
    CareSchedule schedule,
    Species? species,
    int plantId,
  ) async {
    final controller = TextEditingController(
      text: schedule.intervalDays?.toString() ?? '',
    );
    final rec = _speciesRecommendation(schedule, species);
    final careLabel = _careTypeLabel(schedule.careType ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Интервал: $careLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rec != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Рекомендация вида: $rec дн.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Интервал (дней)',
                border: OutlineInputBorder(),
              ),
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
              final value = int.tryParse(controller.text);
              if (value == null || value <= 0) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(apiServiceProvider)
                    .updateScheduleInterval(schedule.id, value);
                ref.invalidate(plantDetailProvider(plantId));
                ref.invalidate(upcomingSchedulesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Интервал обновлён')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref, int plantId) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      await ref.read(apiServiceProvider).uploadPlantPhoto(plantId, file.path);
      ref.invalidate(plantsProvider);
      ref.invalidate(plantDetailProvider(plantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото обновлено')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _showChangeRoomDialog(
      BuildContext context, WidgetRef ref, int plantId, int? currentRoomId) async {
    List<Room> rooms;
    try {
      rooms = await ref.read(apiServiceProvider).getRooms();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки комнат: $e')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    int? selectedRoomId = currentRoomId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Выбрать комнату'),
          content: SingleChildScrollView(
            child: RadioGroup<int?>(
              groupValue: selectedRoomId,
              onChanged: (v) => setState(() => selectedRoomId = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<int?>(
                    title: Text('Не назначена'),
                    value: null,
                  ),
                  ...rooms.map(
                    (room) => RadioListTile<int?>(
                      title: Text(room.name ?? ''),
                      value: room.id,
                    ),
                  ),
                ],
              ),
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
                  await ref.read(apiServiceProvider).updatePlant(
                        plantId,
                        {'room_id': selectedRoomId},
                      );
                  ref.invalidate(plantDetailProvider(plantId));
                  ref.invalidate(plantsProvider);
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

  Future<void> _showAddEventDialog(
      BuildContext context, WidgetRef ref, int plantId) async {
    String selectedCareType = 'water';
    DateTime selectedDate = DateTime.now();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Добавить запись'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCareType,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: const [
                  DropdownMenuItem(
                      value: 'water', child: Text('\u{1F4A7} Полив')),
                  DropdownMenuItem(
                      value: 'fertilize',
                      child: Text('\u{1F331} Подкормка')),
                  DropdownMenuItem(
                      value: 'repot', child: Text('\u{1FAB4} Пересадка')),
                ],
                onChanged: (v) => setState(() => selectedCareType = v!),
              ),
              const SizedBox(height: 8),
              // Выбор даты
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Заметки'),
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
                  final now = DateTime.now();
                  final isToday = selectedDate.year == now.year &&
                      selectedDate.month == now.month &&
                      selectedDate.day == now.day;
                  await ref.read(apiServiceProvider).createEvent(plantId, {
                    'care_type': selectedCareType,
                    if (!isToday)
                      'performed_at': selectedDate.toUtc().toIso8601String(),
                    if (notesController.text.isNotEmpty)
                      'notes': notesController.text,
                  });
                  ref.invalidate(_plantEventsProvider(plantId));
                  ref.invalidate(plantDetailProvider(plantId));
                  ref.invalidate(todayTasksProvider);
                  ref.invalidate(upcomingSchedulesProvider);
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

class _RecommendationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RecommendationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
