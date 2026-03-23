import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/plant_identify_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plants_provider.dart';

class IdentifyResultScreen extends ConsumerWidget {
  final PlantIdentifyResult result;

  const IdentifyResultScreen({super.key, required this.result});

  Future<void> _cancelIdentification(
      BuildContext context, WidgetRef ref) async {
    final plantId = result.plant?.id;
    if (plantId != null) {
      try {
        await ref.read(apiServiceProvider).deletePlant(plantId);
        ref.invalidate(plantsProvider);
      } catch (_) {}
    }
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species = result.species;
    final photoUrl = result.plant?.photoUrl;
    final plantId = result.plant?.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelIdentification(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Результат'),
          leading: BackButton(
            onPressed: () => _cancelIdentification(context, ref),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                species?.commonName ?? '',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                species?.scientificName ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
              ),
              Text('Семейство: ${species?.family ?? ''}'),
              const SizedBox(height: 16),
              Text(species?.description ?? ''),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (species?.waterIntervalDays != null)
                    _InfoCard(
                        '\u{1F4A7} Полив: каждые ${species!.waterIntervalDays} дн.'),
                  if (species?.lightRequirement != null)
                    _InfoCard(
                        '\u{2600}\uFE0F Свет: ${species!.lightRequirement}'),
                  if (species?.temperatureMin != null &&
                      species?.temperatureMax != null)
                    _InfoCard(
                        '\u{1F321}\uFE0F ${species!.temperatureMin}\u2013${species.temperatureMax}\u00B0C'),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: plantId != null
                      ? () {
                          ref.invalidate(plantsProvider);
                          context.go('/collection');
                        }
                      : null,
                  child: const Text('Добавить в коллекцию'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelIdentification(context, ref),
                  child: const Text('Определить ещё'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text),
      ),
    );
  }
}
