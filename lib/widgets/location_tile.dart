import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';

class LocationTile extends ConsumerWidget {
  const LocationTile({
    super.key,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String address;
  final double? latitude;
  final double? longitude;

  bool get _hasLocation =>
      address.trim().isNotEmpty || (latitude != null && longitude != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: _hasLocation ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(label),
        subtitle: Text(_subtitle(l10n)),
        trailing: _hasLocation
            ? Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: l10n.googleMaps,
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _open(context, ref),
                  ),
                  IconButton(
                    tooltip: l10n.copyAddress,
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: address.trim().isEmpty
                        ? null
                        : () => Clipboard.setData(
                              ClipboardData(text: address.trim()),
                            ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final coordinates = latitude != null && longitude != null
        ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
        : '';
    if (address.trim().isEmpty && coordinates.isEmpty) {
      return '-';
    }
    return [address.trim(), coordinates].where((item) => item.isNotEmpty).join('\n');
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(mapServiceProvider).openInGoogleMaps(
            address: address,
            latitude: latitude,
            longitude: longitude,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
