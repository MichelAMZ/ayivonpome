import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_council_member.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/family_council_service.dart';
import '../widgets/family_council_member_card.dart';
import '../widgets/responsive.dart';

class FamilyCouncilScreen extends ConsumerWidget {
  const FamilyCouncilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value;
    final auth = ref.watch(authSessionProvider);
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyCouncil)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    const service = FamilyCouncilService();
    final publicLimited = !auth.isAuthenticated;
    final canManage = service.canManage(auth.session?.role ?? 'viewer');
    final members = service.visibleMembers(
      data,
      publicLimited: publicLimited,
      canManage: canManage,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBFCF7),
      appBar: AppBar(
        title: Text(l10n.familyCouncil),
        actions: [
          if (canManage)
            IconButton(
              tooltip: l10n.addCouncilMember,
              onPressed: () => _showMemberDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8DDBE)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.familyCouncil.title.isEmpty
                        ? l10n.familyCouncil
                        : data.familyCouncil.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.familyCouncil.description.isEmpty
                        ? l10n.councilDescription
                        : data.familyCouncil.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.councilMembers),
              ),
            )
          else
            ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              spacing: 14,
              mainAxisExtent: 238,
              children: [
                for (final member in members)
                  _memberCard(
                    context,
                    ref,
                    member,
                    canManage: canManage,
                    showContact: service.canShowContact(
                      member,
                      publicLimited: publicLimited,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _memberCard(
    BuildContext context,
    WidgetRef ref,
    FamilyCouncilMember member, {
    required bool canManage,
    required bool showContact,
  }) {
    return FamilyCouncilMemberCard(
      member: member,
      showContact: showContact,
      showDetails: authModeAllowsDetails(ref, member),
      onEmail: member.email.isEmpty
          ? null
          : () => ref
                .read(communicationServiceProvider)
                .sendEmail(
                  email: member.email,
                  subject: AppLocalizations.of(context).familyEmailSubject,
                  body: AppLocalizations.of(context).familyEmailBody,
                ),
      onWhatsApp: member.whatsappNumber.isEmpty
          ? null
          : () => ref
                .read(communicationServiceProvider)
                .openWhatsApp(
                  phoneNumber: member.whatsappNumber,
                  message: AppLocalizations.of(context).familyWhatsappMessage,
                ),
      onCall: member.phoneNumber.isEmpty
          ? null
          : () => ref
                .read(communicationServiceProvider)
                .makePhoneCall(member.phoneNumber),
      onMap: member.residencePlace.isEmpty
          ? null
          : () => ref
                .read(mapServiceProvider)
                .openInGoogleMaps(address: member.residencePlace),
      onEdit: canManage ? () => _showMemberDialog(context, ref, member) : null,
      onDelete: canManage ? () => _deleteMember(context, ref, member) : null,
    );
  }

  bool authModeAllowsDetails(WidgetRef ref, FamilyCouncilMember member) {
    final auth = ref.read(authSessionProvider);
    return auth.isAuthenticated && member.allowContact;
  }

  Future<void> _deleteMember(
    BuildContext context,
    WidgetRef ref,
    FamilyCouncilMember member,
  ) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .deleteFamilyCouncilMember(
          member,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _showMemberDialog(
    BuildContext context,
    WidgetRef ref, [
    FamilyCouncilMember? member,
  ]) async {
    final l10n = AppLocalizations.of(context);
    final firstName = TextEditingController(text: member?.firstName ?? '');
    final lastName = TextEditingController(text: member?.lastName ?? '');
    final roleTitle = TextEditingController(text: member?.roleTitle ?? '');
    final residence = TextEditingController(text: member?.residencePlace ?? '');
    final email = TextEditingController(text: member?.email ?? '');
    final phone = TextEditingController(text: member?.phoneNumber ?? '');
    final whatsapp = TextEditingController(text: member?.whatsappNumber ?? '');
    final photo = TextEditingController(text: member?.photo ?? '');
    final order = TextEditingController(text: (member?.order ?? 0).toString());
    var active = member?.active ?? true;
    var allowContact = member?.allowContact ?? true;

    final saved = await showDialog<FamilyCouncilMember>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            member == null ? l10n.addCouncilMember : l10n.editCouncilMember,
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roleTitle,
                    decoration: InputDecoration(labelText: l10n.roleInCouncil),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: residence,
                    decoration: InputDecoration(labelText: l10n.residencePlace),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: whatsapp,
                    decoration: const InputDecoration(labelText: 'WhatsApp'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: photo,
                    decoration: const InputDecoration(labelText: 'Photo'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordre'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    title: const Text('Actif'),
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: allowContact,
                    title: const Text('Autoriser les contacts'),
                    onChanged: (value) =>
                        setDialogState(() => allowContact = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                FamilyCouncilMember(
                  id: member?.id ?? '',
                  personId: member?.personId ?? '',
                  firstName: firstName.text.trim(),
                  lastName: lastName.text.trim(),
                  roleTitle: roleTitle.text.trim(),
                  residencePlace: residence.text.trim(),
                  email: email.text.trim(),
                  phoneNumber: phone.text.trim(),
                  whatsappNumber: whatsapp.text.trim(),
                  photo: photo.text.trim(),
                  active: active,
                  order: int.tryParse(order.text) ?? 0,
                  allowContact: allowContact,
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    firstName.dispose();
    lastName.dispose();
    roleTitle.dispose();
    residence.dispose();
    email.dispose();
    phone.dispose();
    whatsapp.dispose();
    photo.dispose();
    order.dispose();
    if (saved == null) return;

    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .upsertFamilyCouncilMember(
          saved,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }
}
