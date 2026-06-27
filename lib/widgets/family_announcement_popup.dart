import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_announcement.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';

class FamilyAnnouncementPopup extends ConsumerStatefulWidget {
  const FamilyAnnouncementPopup({
    super.key,
    required this.announcements,
    required this.data,
  });

  final List<FamilyAnnouncementHistory> announcements;
  final FamilyTreeData data;

  @override
  ConsumerState<FamilyAnnouncementPopup> createState() =>
      _FamilyAnnouncementPopupState();
}

class _FamilyAnnouncementPopupState
    extends ConsumerState<FamilyAnnouncementPopup> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcements[_index];
    final auth = ref.watch(authSessionProvider);
    final person = widget.data.people
        .where((item) => item.id == announcement.memberId)
        .firstOrNull;
    if (person == null) return const SizedBox.shrink();
    final isBirthday = announcement.type == 'birthday';
    final service = ref.read(familyAnnouncementServiceProvider);
    final phone = service.contactPhone(person);
    final whatsAppMessage = isBirthday
        ? service.birthdayWhatsAppMessage(person)
        : service.birthWhatsAppMessage(person);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBirthday
                        ? const [Color(0xFFFFF4D8), Color(0xFFFFE4EC)]
                        : const [Color(0xFFEAF7FF), Color(0xFFFFF1F7)],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isBirthday
                          ? Icons.celebration_outlined
                          : Icons.child_friendly_outlined,
                      size: 74,
                      color: isBirthday
                          ? const Color(0xFFC57A12)
                          : const Color(0xFF2F80ED),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBirthday ? 'Joyeux anniversaire' : 'Nouvelle naissance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      person.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBirthday
                          ? _birthdayDate(person.birthDate)
                          : _fullDate(person.birthDate),
                      textAlign: TextAlign.center,
                    ),
                    if (!isBirthday) ...[
                      const SizedBox(height: 6),
                      Text(
                        _parentsLine(person),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Text(
                  announcement.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (widget.announcements.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${_index + 1} / ${widget.announcements.length}'),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyMessage(whatsAppMessage),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copier le message'),
                    ),
                    OutlinedButton.icon(
                      onPressed: phone.isEmpty || !auth.isAdmin
                          ? null
                          : () => _openWhatsApp(
                              announcement,
                              phone,
                              whatsAppMessage,
                            ),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(
                        !auth.isAdmin
                            ? 'Réservé aux administrateurs'
                            : phone.isEmpty
                            ? 'Numéro WhatsApp indisponible'
                            : 'Envoyer WhatsApp',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _mark(announcement, 'skipped'),
                      child: const Text('Ne plus afficher aujourd’hui'),
                    ),
                    if (_index < widget.announcements.length - 1)
                      FilledButton(
                        onPressed: () => setState(() => _index++),
                        child: const Text('Suivant'),
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

  Future<void> _copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message copié')));
    }
  }

  Future<void> _openWhatsApp(
    FamilyAnnouncementHistory announcement,
    String phone,
    String message,
  ) async {
    try {
      await ref
          .read(communicationServiceProvider)
          .openWhatsApp(phoneNumber: phone, message: message);
      await _mark(announcement, 'opened', close: false);
    } catch (_) {
      await _mark(announcement, 'failed', close: false);
    }
  }

  Future<void> _mark(
    FamilyAnnouncementHistory announcement,
    String status, {
    bool close = true,
  }) async {
    await ref
        .read(familyTreeProvider.notifier)
        .updateFamilyAnnouncementStatus(announcement, status);
    if (!mounted || !close) return;
    if (_index < widget.announcements.length - 1) {
      setState(() => _index++);
      return;
    }
    Navigator.pop(context);
  }

  String _parentsLine(Person person) {
    final father = widget.data.people
        .where((item) => item.id == person.fatherId)
        .firstOrNull
        ?.fullName;
    final mother = widget.data.people
        .where((item) => item.id == person.motherId)
        .firstOrNull
        ?.fullName;
    final values = [
      if (father != null && father.isNotEmpty) 'Père : $father',
      if (mother != null && mother.isNotEmpty) 'Mère : $mother',
    ];
    return values.isEmpty ? '' : values.join(' · ');
  }

  String _birthdayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _fullDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
