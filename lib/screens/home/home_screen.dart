import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/plants_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/care_task_card.dart';
import '../../widgets/loading_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Color _chipColor(int days) {
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber[700]!;
    return Colors.green;
  }

  String _groupLabel(int days, DateTime nextDue) {
    if (days == 1) {
      return 'Завтра (${DateFormat('dd.MM').format(nextDue)})';
    }
    return DateFormat('dd.MM.yyyy').format(nextDue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationInitProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final upcomingAsync = ref.watch(upcomingSchedulesProvider);

    ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (prev, next) async {
      final wasOnline = prev?.valueOrNull ?? true;
      final isNowOnline = next.valueOrNull ?? true;
      if (!wasOnline && isNowOnline) {
        // 1. Отправить ВСЕ оффлайн-изменения на сервер.
        await ref.read(syncServiceProvider).syncPendingActions();
        // 2. Дать серверу время обработать изменения.
        await Future.delayed(const Duration(milliseconds: 500));
        // 3. Обновить данные с сервера — они уже содержат наши правки.
        ref.invalidate(plantsProvider);
        ref.invalidate(todayTasksProvider);
        ref.invalidate(upcomingSchedulesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные синхронизированы')),
          );
        }
      } else if (wasOnline && !isNowOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Нет подключения. Работа в оффлайн-режиме.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Сегодня')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayTasksProvider);
          ref.invalidate(upcomingSchedulesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Today section ──────────────────────────────
              Row(
                children: [
                  Icon(Icons.today,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Задачи на сегодня',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              tasksAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingIndicator(),
                ),
                error: (e, _) => Text('Ошибка: $e'),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Все задачи выполнены!'),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: tasks.map((schedule) {
                      return CareTaskCard(
                        schedule: schedule,
                        onTap: () => context
                            .push('/plant/${schedule.plantId ?? 0}'),
                        onComplete: () async {
                          try {
                            await ref
                                .read(apiServiceProvider)
                                .completeSchedule(schedule.id);
                            ref.invalidate(todayTasksProvider);
                            ref.invalidate(upcomingSchedulesProvider);
                            ref.invalidate(plantsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Готово!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          }
                        },
                        onSnooze: () async {
                          try {
                            await ref
                                .read(apiServiceProvider)
                                .snoozeSchedule(schedule.id);
                            ref.invalidate(todayTasksProvider);
                            ref.invalidate(upcomingSchedulesProvider);
                            ref.invalidate(plantsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Отложено на завтра')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              // ── Upcoming section ───────────────────────────
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Ближайшие 7 дней',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              upcomingAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text('Ошибка: $e'),
                data: (upcoming) {
                  if (upcoming.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Нет запланированных мероприятий'),
                    );
                  }

                  // Group by daysUntil
                  final grouped = <int, List<UpcomingItem>>{};
                  for (final item in upcoming) {
                    (grouped[item.daysUntil] ??= []).add(item);
                  }
                  final sortedDays = grouped.keys.toList()..sort();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedDays.map((days) {
                      final items = grouped[days]!;
                      final date = items.first.schedule.nextDue!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _groupLabel(days, date),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                          ...items.map((item) {
                            final photoUrl = item.plant.photoUrl;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundImage: photoUrl != null
                                    ? CachedNetworkImageProvider(photoUrl)
                                        as ImageProvider
                                    : null,
                                child: photoUrl == null
                                    ? const Icon(Icons.eco, size: 16)
                                    : null,
                              ),
                              title: Text(
                                  item.plant.nickname ?? 'Растение'),
                              subtitle: Text(
                                  careTypeLabel(item.schedule.careType ?? '')),
                              trailing: Chip(
                                label: Text(
                                  item.daysUntil == 1
                                      ? 'Завтра'
                                      : 'Через ${item.daysUntil} дн.',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor:
                                    _chipColor(item.daysUntil),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                              ),
                              onTap: () => context
                                  .push('/plant/${item.plant.id}'),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
