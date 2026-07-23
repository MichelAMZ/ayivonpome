# Journal des modifications de l'audit préproduction

## Phase 1 — 20 juillet 2026

### Actions réalisées

- Vérification de l'état Git et conservation des modifications locales.
- Création de la branche `audit/preprod-readiness`.
- Inventaire des plateformes, dépendances, modules, tests et configurations Firebase.
- Exécution des diagnostics Flutter/Dart.
- Analyse statique des règles Firestore, de l'authentification et des emplacements susceptibles de contenir des secrets.
- Création du rapport `docs/audit/preprod_inventory.md`.

### Changements de code métier

Aucun.

### Changements de données ou infrastructure

Aucun :

- aucune écriture Firestore ;
- aucune règle distante modifiée ;
- aucun déploiement Firebase ;
- aucun DNS modifié ;
- aucun fichier supprimé.

### Modifications locales antérieures, exclues de l'audit

- `assets/data/family_tree.json` ;
- `lib/services/sync_service.dart` ;
- `test/data/ayivon_bundled_tree_test.dart` ;
- `test/services/sync_service_test.dart` ;
- `tool/` non suivi.

### Commandes réussies

- `git checkout -b audit/preprod-readiness`
- `flutter --version`
- `flutter doctor -v`
- `flutter pub get`
- `flutter pub outdated`
- `flutter analyze`
- `flutter test`
- recherches statiques avec `rg`

### Commandes en échec ou incomplètes

- `dart format --output=none --set-exit-if-changed .` : code de sortie 1, 16 fichiers non formatés. Les réécritures produites par l'outil ont été annulées immédiatement.
- `npm test` dans `functions/` : script `test` absent; le script déclaré est `test:rules`.
- `npm run test:rules` : non exécuté à cause d'une erreur intermittente du lanceur Windows `CreateProcessAsUserW 1312`, et non d'un résultat de test négatif.
- Plusieurs commandes composites ont rencontré la même erreur de session Windows; elles ont été remplacées par des commandes unitaires lorsque possible.

### Résultats de validation

- Flutter doctor : aucun problème.
- Analyse Flutter : aucun diagnostic.
- Tests Flutter : 127 réussis, 0 échec.
- Format : 16 fichiers à corriger dans une phase ultérieure.
- Tests de règles Firestore : statut inconnu.

### Prochaine étape proposée

Attendre la validation humaine de la phase 1, puis préparer une phase 2 centrée sur :

1. révocation et retrait des codes embarqués ;
2. séparation des données publiques et privées ;
3. tests de règles sur émulateur ;
4. environnement Firebase staging indépendant.

## Phase 2 — Étape 1 — 20 juillet 2026

### Actions réalisées

- Confirmation de la branche `audit/preprod-readiness` et conservation de l'état local.
- Inventaire des champs de codes dans l'asset, les modèles, les tests et les flux de stockage.
- Analyse des usages de `AuthCodeService`, `ModificationCodeService`, `AdminAccessService` et `FirebaseAccessCodeAuthService`.
- Confirmation de fallbacks accordant encore des rôles ou capacités depuis des données locales.
- Classification complète des champs du modèle `Person` par niveau de sensibilité.
- Création du rapport initial de remédiation de phase 2.

### Changements fonctionnels

Aucun. Cette étape est strictement analytique.

### Infrastructure et données distantes

- aucune règle modifiée ou déployée ;
- aucune donnée Firestore lue ou écrite ;
- aucun compte Firebase modifié ;
- aucun hébergement déployé.

### Problèmes restant ouverts

- P0-SEC-001 : séparation public/privé non encore implémentée ;
- P0-SEC-002 : codes exposés non encore retirés ;
- P1-AUTH-001 : autorisations locales fondées sur des codes statiques ;
- P1-DATA-001 : absence d'identifiant de propriétaire de fiche vérifiable.

### Décision

Étape 1 terminée. L'étape 2 est techniquement possible, mais n'est pas commencée sans validation de ce constat intermédiaire.

## Phase 2 — Étape 2 — 20 juillet 2026

### Actions réalisées

- Retrait des codes actifs de l'asset familial.
- Neutralisation des valeurs sensibles par défaut et des anciennes valeurs désérialisées.
- Suppression des fallbacks locaux de connexion et de modification.
- Remplacement de la validation KPI locale par une garde Firebase vérifiée.
- Durcissement des permissions calculées à partir de `AuthState`.
- Ajout d'une migration locale de nettoyage idempotente.
- Ajout d'un scanner anti-secrets et de sa documentation.
- Adaptation et ajout de tests de refus par défaut.
- Construction Web release et inspection des artefacts.

### Validations

- `flutter pub get` : réussi.
- `flutter analyze` : réussi, aucun diagnostic.
- `flutter test` : 132 réussis, 0 échec.
- `dart run tooling/security/check_secrets.dart` : réussi.
- `flutter build web --release` : réussi.
- scanner avec `--include-build` : réussi.

### Commande de format

Seuls les fichiers Dart modifiés ont été formatés. Une tentative initiale incluant par erreur le fichier JSON a signalé que JSON n'est pas une source Dart; aucun contenu JSON n'a été altéré par cette erreur.

### Actions non réalisées

- aucune écriture ou migration Firestore ;
- aucune modification de règle Firestore ;
- aucun déploiement ;
- aucune révocation de compte ou rôle distant ;
- aucune séparation public/privé de `members`.

### Décision

Étape 2 validée sous conditions. La révocation distante manuelle reste obligatoire et P0-SEC-001 demeure bloquant avant préproduction.

## Phase 2 — Étape 3 — 20 juillet 2026

- Ajout des projections physiques `members_public` et `members_private`.
- Chargement privé à la demande et fallback legacy strictement filtré.
- Ajout de tests de non-divulgation des champs sensibles.
- Adaptation du diagnostic Firestore au chemin public imbriqué.
- Aucune migration distante, modification de règles ou opération de
  déploiement.

## Phase 2 — Étape 4 — 20 juillet 2026

- Durcissement local complet de `firestore.rules` pour le schéma public/privé.
- Écritures clientes de `user_roles` et de `ownerUid` refusées.
- Collection `members` legacy retirée de la lecture publique.
- Ajout de Firebase Emulator Suite et d'un projet factice par défaut.
- Ajout de 41 tests de règles couvrant rôles, champs, isolation et requêtes.
- Ajout de trois index locaux `members_public`.
- Ajout de tests Flutter pour sessions expirées, UID et rôle absents.
- Aucun déploiement, aucune migration et aucune écriture distante.

## Phase 2 — Étape 5, étapes 1 à 10 — 20 juillet 2026

- Ajout des environnements Flutter dev/staging/prod et garde-fous projectId.
- Ajout de la bannière PRÉPRODUCTION.
- Ajout de l’anonymiseur et de l’outil de dry-run split members.
- Sauvegarde locale ignorée par Git et checksum SHA-256 validé.
- Deux dry-runs identiques : 23 membres, 0 P0, 0 P1.
- Aucun staging réel identifié ; aucun alias staging inventé.
- Aucun `--apply`, déploiement, compte distant ou Hosting.
