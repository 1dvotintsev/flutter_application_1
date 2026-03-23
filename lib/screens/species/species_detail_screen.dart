import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../models/species.dart';
import '../../widgets/loading_indicator.dart';

final _speciesDetailProvider =
    FutureProvider.autoDispose.family<Species, int>((ref, id) {
  return ref.read(apiServiceProvider).getSpecies(id);
});

class SpeciesDetailScreen extends ConsumerWidget {
  final String speciesId;

  const SpeciesDetailScreen({super.key, required this.speciesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.parse(speciesId);
    final speciesAsync = ref.watch(_speciesDetailProvider(id));

    return speciesAsync.when(
      loading: () =>
          Scaffold(appBar: AppBar(), body: const LoadingIndicator()),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('Ошибка: $e'))),
      data: (species) => Scaffold(
        appBar: AppBar(title: Text(species.commonName ?? '')),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (species.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: species.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  height: 250,
                  color: Colors.green[50],
                  child: const Center(
                      child: Icon(Icons.eco, size: 80, color: Colors.green)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(
                species.scientificName ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
              Text('Семейство: ${species.family ?? ''}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(species.description ?? ''),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('\u{1F4A7}',
                          style: TextStyle(fontSize: 24)),
                      title: const Text('Полив'),
                      subtitle: Text(
                          'каждые ${species.waterIntervalDays ?? '?'} дней'),
                    ),
                    ListTile(
                      leading: const Text('\u{1F331}',
                          style: TextStyle(fontSize: 24)),
                      title: const Text('Подкормка'),
                      subtitle: Text(
                          'каждые ${species.fertilizeIntervalDays ?? '?'} дней'),
                    ),
                    ListTile(
                      leading: const Text('\u{1FAB4}',
                          style: TextStyle(fontSize: 24)),
                      title: const Text('Пересадка'),
                      subtitle: Text(
                          'каждые ${species.repotIntervalMonths ?? '?'} месяцев'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('\u{2600}\uFE0F',
                          style: TextStyle(fontSize: 24)),
                      title: const Text('Освещение'),
                      subtitle: Text(species.lightRequirement ?? ''),
                    ),
                    if (species.temperatureMin != null &&
                        species.temperatureMax != null)
                      ListTile(
                        leading: const Text('\u{1F321}\uFE0F',
                            style: TextStyle(fontSize: 24)),
                        title: const Text('Температура'),
                        subtitle: Text(
                            '${species.temperatureMin}\u2013${species.temperatureMax} \u00B0C'),
                      ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
