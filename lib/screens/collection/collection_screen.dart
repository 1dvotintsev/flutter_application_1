import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/plants_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/plant_grid_card.dart';
import '../../widgets/loading_indicator.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  int? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider(_selectedRoomId));
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Коллекция'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/plant/add'),
          ),
        ],
      ),
      body: plantsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (plants) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(plantsProvider);
              ref.invalidate(roomsProvider);
            },
            child: Column(
              children: [
                roomsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (rooms) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Все'),
                          selected: _selectedRoomId == null,
                          onSelected: (_) =>
                              setState(() => _selectedRoomId = null),
                        ),
                        ...rooms.map((room) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(room.name ?? ''),
                                selected: _selectedRoomId == room.id,
                                onSelected: (_) =>
                                    setState(() => _selectedRoomId = room.id),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: plants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Добавьте первое растение!'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.push('/plant/add'),
                                child: const Text('Добавить'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: plants.length,
                          itemBuilder: (context, index) {
                            final plant = plants[index];
                            return PlantGridCard(
                              plant: plant,
                              onTap: () => context.push('/plant/${plant.id}'),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
