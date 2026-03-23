import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/care_schedule.dart';

String careTypeLabel(String careType) {
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

class CareTaskCard extends StatelessWidget {
  final CareSchedule schedule;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const CareTaskCard({
    super.key,
    required this.schedule,
    required this.onComplete,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = schedule.plant?.photoUrl;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: photoUrl != null
                    ? CachedNetworkImageProvider(photoUrl) as ImageProvider
                    : null,
                child: photoUrl == null ? const Icon(Icons.eco) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.plant?.nickname ?? 'Растение',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      careTypeLabel(schedule.careType ?? ''),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: Colors.green,
                onPressed: onComplete,
              ),
              IconButton(
                icon: const Icon(Icons.snooze),
                color: Colors.orange,
                onPressed: onSnooze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
