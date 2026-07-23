# Inventaire de préparation à la préproduction

Date de l'audit : 20 juillet 2026
Branche : `audit/preprod-readiness`
Périmètre : phase 1 uniquement — inventaire et diagnostic, sans déploiement ni écriture distante.

## Résumé exécutif

L'application Flutter est compilable au niveau analyse statique et sa suite de 127 tests passe. L'outillage local est complet pour Web, Android et Windows, mais le dépôt ne configure effectivement que Web, Android, iOS et Linux. Deux risques P0 interdisent néanmoins une préproduction en l'état : exposition potentielle de données privées par les lectures publiques Firestore, et codes d'accès historiques présents en clair dans l'asset embarqué.

Verdict provisoire de phase 1 : **NO-GO PREPROD**.

## État Git avant audit

- Dépôt Git valide, branche initiale `main`.
- Branche dédiée créée : `audit/preprod-readiness`.
- Modifications locales préexistantes préservées :
  - `assets/data/family_tree.json` ;
  - `lib/services/sync_service.dart` ;
  - `test/data/ayivon_bundled_tree_test.dart` ;
  - `test/services/sync_service_test.dart` ;
  - dossier non suivi `tool/`.
- Aucun reset, suppression ou écrasement effectué.

## Environnement et plateformes

| Élément | État |
|---|---|
| Flutter | 3.44.6 stable |
| Dart | 3.12.2 |
| Windows hôte | Windows 11 25H2 |
| Android SDK | 36.1.0, licences acceptées |
| Java | OpenJDK 21 |
| Navigateurs | Chrome 150, Edge 150 |
| Web | configuré |
| Android | dossier présent, `google-services.json` absent |
| iOS | dossier présent, `GoogleService-Info.plist` absent |
| Linux | dossier présent |
| Windows/macOS | dossiers absents |

`flutter doctor -v` ne signale aucun problème sur la machine d'audit.

## Architecture observée

Le dépôt contient 224 fichiers Dart applicatifs et 41 fichiers de tests Dart.

- `lib/core/` : initialisation Firebase et infrastructure réseau.
- `lib/data/` : clients Firestore, API distante et repositories locaux.
- `lib/features/` : logique métier structurée par fonctionnalité, encore minoritaire.
- `lib/models/` : modèles sérialisables de l'arbre, synchronisation, rôles et administration.
- `lib/providers/` : orchestration Riverpod et état local-first.
- `lib/services/` : synchronisation, relations, diagnostics, authentification et métiers transverses.
- `lib/screens/` et `lib/widgets/` : présentation Flutter.
- `functions/` : deux fonctions callable d'authentification/rotation de code et tests de règles.
- `api/` : backend PHP distinct avec migrations et authentification propres.

La séparation repository/service/provider existe, mais plusieurs fichiers concentrent trop de responsabilités : `admin_dashboard_screen.dart` (plus de 6 000 lignes), `person_edit_screen.dart` (plus de 3 000), `family_tree_provider.dart` (plus de 2 600) et `app_shell.dart` (près de 2 000). C'est un risque de régression P2, pas un motif de refactorisation globale immédiate.

## Dépendances

Dépendances structurantes : Riverpod 3, Firebase Core/Auth/Firestore/Functions, connectivity_plus, shared_preferences, notifications locales, file_picker, http, intl et uuid.

`flutter pub outdated` indique :

- 3 dépendances directement actualisables sans changer les contraintes ;
- 19 dépendances contraintes sous une version majeure résoluble ;
- migrations majeures disponibles pour Firebase Core/Auth/Firestore/Functions, notifications et file_picker ;
- 36 packages au total avec une version plus récente incompatible avec les contraintes actuelles.

Aucune mise à niveau n'a été appliquée pendant la phase 1.

## Qualité et tests

| Contrôle | Résultat |
|---|---|
| `flutter pub get` | réussi |
| `flutter analyze` | réussi, aucun diagnostic |
| `flutter test` | réussi, 127 tests |
| format Dart | échec : 16 fichiers non conformes |
| tests de règles | non exécutés : lanceur Windows défaillant après invocation npm |
| build release | non exécuté en phase 1 |

Les tests couvrent notamment les modèles, relations, cycles, confidentialité, providers, synchronisation, formulaires et certains widgets. Les tests d'intégration Firebase/émulateur et la matrice responsive complète ne sont pas démontrés par la suite actuelle.

## Firebase et authentification

- Initialisation automatique dans `main.dart` via `FirebaseBootstrap`.
- Persistance Auth locale activée sur Web.
- Cache Firestore persistant et illimité demandé.
- Configuration par `dart-define` possible, mais un projet Firebase réel est utilisé par défaut.
- Aucun `firebase_options.dart` généré.
- Les options par défaut correspondent à une application Web et sont réutilisées pour toutes les plateformes.
- Aucun branchement aux émulateurs Auth/Firestore détecté.
- Aucun fichier de configuration Firebase natif Android/iOS détecté.
- La restauration de session contrôle `active`, le rôle, `familyIds` et l'expiration.
- L'accès par code essaie le code saisi comme mot de passe de comptes techniques dont les emails sont connus du client.
- Deux Cloud Functions callable existent, mais aucune preuve de disponibilité en environnement de préproduction n'est fournie dans cette phase.

## Firestore et collections

Collections utilisées ou couvertes par les règles :

- `families` ;
- `members` ;
- `relationships` ;
- `family_tree_links` ;
- `notifications` ;
- `activity_logs` ;
- `admin_audit_logs` ;
- `sync_incidents` ;
- `diagnostic_ping` ;
- `access_code_configs` ;
- `access_code_audit_logs` ;
- `settings` ;
- `user_roles`.

Les écritures de membres vérifient le tenant, la progression de version et la protection de `deletedAt`. Les rôles sont lus dans `user_roles` et une élévation directe est réservée au super administrateur. En revanche, les règles ne valident pas systématiquement les types, listes de champs, tailles et timestamps.

Aucune donnée Firestore réelle n'a été modifiée ni auditée exhaustivement pendant cette phase. Le dry run généalogique antérieur n'est pas assimilé à un audit global de la base.

## Sécurité et secrets

Les clés Firebase clientes (`apiKey`, `appId`, `projectId`) sont des identifiants publics d'application et ne constituent pas à elles seules un secret. Aucun service account ni clé privée suivie n'a été identifié par la recherche statique.

Risques critiques :

### PREPROD-SEC-001 — P0 — lecture publique de documents privés

- Fichier : `firestore.rules`, règles `members`, `relationships`, `family_tree_links` et `notifications`.
- Constat : la famille `ayivon` est publiquement lisible au niveau du document complet.
- Impact : les champs privés stockés avec un membre peuvent être récupérés directement via l'API Firestore, même si l'UI les masque.
- Correction proposée : séparer documents publics et privés ou restreindre les lectures complètes aux utilisateurs autorisés, avec tests d'émulateur.
- Statut : ouvert; correction sensible à préparer en phase 2.

### PREPROD-SEC-002 — P0 — codes historiques embarqués en clair

- Fichier : `assets/data/family_tree.json`.
- Constat : codes d'accès, de modification et d'administration présents dans un asset livré au navigateur.
- Impact : toute valeur encore valide est publiquement récupérable et peut compromettre des comptes techniques.
- Correction proposée : révoquer/faire tourner les valeurs côté Firebase, retirer les codes du client, migrer vers la validation serveur et nettoyer l'historique Git si nécessaire.
- Statut : ouvert; nécessite coordination et rotation sécurisée.

### PREPROD-AUTH-001 — P1 — comptes techniques connus du client

- Fichier : `lib/services/firebase_access_code_auth_service.dart`.
- Constat : le client essaie un code comme mot de passe sur une liste d'emails techniques prédéfinis.
- Impact : facilite l'énumération et couple un secret familial à un mot de passe Firebase partagé.
- Correction proposée : authentification par fonction callable sécurisée produisant un jeton personnalisé, limitation de débit et audit serveur.

## Configuration des environnements

- Aucun `lib/config/app_environment.dart`.
- Aucun découpage explicite dev/staging/prod.
- Aucun projet Firebase de staging déclaré.
- Firebase production est activé par défaut.
- Aucun `.env.example` Flutter à la racine; seul `api/.env.example` existe.
- Aucun bloc `emulators` dans `firebase.json`.
- Aucun workflow GitHub Actions détecté.

Ces absences rendent possible une utilisation accidentelle de la production pendant les tests et constituent un P1 de préparation.

## Gestion d'erreurs et observabilité

- Le bootstrap capture les erreurs Firebase et autorise un démarrage dégradé.
- Un service de diagnostic et un reporter d'incidents existent.
- Aucun gestionnaire global `FlutterError.onError`, `PlatformDispatcher.instance.onError` ou `runZonedGuarded` n'a été détecté.
- Environ 75 blocs `catch` et 132 appels de journalisation debug nécessitent une revue ciblée des erreurs silencieuses et des données consignées.
- Les tests affichent volontairement des stack traces techniques; leur exposition dans l'UI reste à vérifier.

## Hébergement, domaines et CI/CD

- Hosting sert `build/web` avec réécriture SPA vers `index.html`.
- Aucun header explicite de cache ou de sécurité n'est configuré.
- Aucun canal de prévisualisation n'est déclaré.
- La configuration DNS et le certificat du domaine personnalisé n'ont pas été vérifiés en phase 1.
- Aucune CI de validation n'est présente.
- Aucun déploiement n'a été effectué.

## Problèmes classés

| ID | Sévérité | Description | Statut |
|---|---|---|---|
| PREPROD-SEC-001 | P0 | Documents membres complets publiquement lisibles | ouvert |
| PREPROD-SEC-002 | P0 | Codes historiques livrés en clair | ouvert |
| PREPROD-AUTH-001 | P1 | Authentification par comptes techniques partagés | ouvert |
| PREPROD-ENV-001 | P1 | Aucun environnement staging séparé | ouvert |
| PREPROD-FB-001 | P1 | Configuration native Android/iOS non démontrée | ouvert |
| PREPROD-EMU-001 | P1 | Émulateurs non configurés et tests de règles non validés | ouvert |
| PREPROD-OBS-001 | P2 | Gestion globale des erreurs absente | ouvert |
| PREPROD-FMT-001 | P2 | 16 fichiers échouent au contrôle de format | ouvert |
| PREPROD-ARCH-001 | P2 | Écrans/providers monolithiques | ouvert |
| PREPROD-PERF-001 | P2 | Listeners et lectures complètes à quantifier | ouvert |
| PREPROD-UI-001 | P2 | Matrice responsive non exécutée | ouvert |
| PREPROD-CI-001 | P2 | Pipeline CI absente | ouvert |

## Risques immédiats et blocages

1. Ne pas ouvrir une préproduction à des utilisateurs réels avant correction des deux P0.
2. Révoquer d'abord côté serveur tout code embarqué susceptible d'être encore valide; retirer seulement le JSON ne suffit pas.
3. Concevoir et tester les règles dans l'émulateur avant tout déploiement.
4. Créer un projet Firebase staging séparé avant les tests d'intégration.
5. Vérifier les options Firebase Android/iOS sur appareils réels.

## Éléments manquants pour la suite

- revue d'architecture détaillée ;
- audit Firestore distant en lecture seule avec rapport JSON/Markdown ;
- tests de règles via Emulator Suite ;
- environnement dev/staging/prod ;
- audit responsive aux sept dimensions demandées ;
- mesures de lectures et performances ;
- builds release Web/Android ;
- checklist DNS et domaine ;
- CI et manuel de recette ;
- rapport final complet après phases 2 à 4.

## Conclusion de phase 1

Le code Dart analysé et les tests locaux donnent une base fonctionnelle encourageante. La sécurité des données et la séparation des environnements empêchent cependant toute qualification préproduction. Aucun changement important ne doit commencer sans validation du plan de correction des P0.
