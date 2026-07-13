import 'package:flutter/material.dart';

class LogoUploadCard extends StatelessWidget {
  const LogoUploadCard({
    super.key,
    required this.fileName,
    required this.onUpload,
    required this.onDelete,
    required this.onRestore,
  });

  final String fileName;
  final VoidCallback onUpload;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined),
              title: const Text('Logo familial'),
              subtitle: Text(fileName.isEmpty ? 'Logo par défaut' : fileName),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer'),
                ),
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurer'),
                ),
                OutlinedButton.icon(
                  onPressed: fileName.isEmpty ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
