import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';

class MiniMapCard extends ConsumerWidget {
  const MiniMapCard({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String address;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasLocation =
        address.trim().isNotEmpty || (latitude != null && longitude != null);
    if (!hasLocation) {
      return const SizedBox.shrink();
    }
    return Card(
      child: InkWell(
        onTap: () => ref.read(mapServiceProvider).openInGoogleMaps(
              address: address,
              latitude: latitude,
              longitude: longitude,
            ),
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Positioned.fill(
                child: Icon(Icons.map_outlined, size: 72),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: FilledButton.icon(
                  onPressed: () => ref.read(mapServiceProvider).openInGoogleMaps(
                        address: address,
                        latitude: latitude,
                        longitude: longitude,
                      ),
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(l10n.viewOnMap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
