# Phase 2 — Remédiation sécurité

Date : 20 juillet 2026
Branche : `audit/preprod-readiness`
Verdict courant : **NO-GO PREPROD**.

## Étape 1 — Analyse, sans correction

### Codes et données d'accès détectés

Les valeurs ne sont volontairement pas reproduites dans ce rapport.

Emplacements confirmés :

- `assets/data/family_tree.json` : `accessCodes`, `modificationCodes`, `adminAccess.currentAdminCode`, historique de code et objets administrateurs ;
- `lib/models/family_tree_data.dart` : données de démonstration contenant des codes et rôles statiques ;
- `lib/models/admin_access.dart` : valeur administrative par défaut codée en dur ;
- tests de services : exemples de codes, dont au moins une forme identique ou dérivée d'une valeur historique ;
- stockage local : le JSON complet est sérialisé, ce qui persiste ces valeurs dans localStorage/stockage applicatif ;
- imports/exports : les structures de codes sont conservées lors de certaines fusions.

Le service `AuthCodeService` supprime explicitement l'ancien code familial de `SharedPreferences`, mais cela ne neutralise pas les codes sérialisés dans `FamilyTreeData`.

### Usages de sécurité concernés

| Parcours | Décision actuelle | Risque |
|---|---|---|
| Connexion générale | `AuthCodeService.verifyCode` peut créer une session et un rôle depuis `familyCodes` local | rôle UI déterminé côté client |
| Modification | si Firebase est indisponible, `ModificationCodeService.validate` peut activer `hasModificationAccess` depuis le JSON local | capacité locale accordée par secret statique |
| KPI/admin | `AdminAccessService.validate` compare le code au JSON local | écran/admin local déverrouillable côté client |
| Auth Firebase par code | le code saisi est essayé comme mot de passe de comptes techniques connus | secret partagé, énumération facilitée |
| Firestore | règles et `user_roles` restent l'autorité finale pour plusieurs écritures | protection partielle seulement; ne corrige pas l'élévation UI/local |

### Données membres

Le document `members` actuel mélange graphe public, contacts, adresses, coordonnées, historique, notes, préférences de confidentialité et métadonnées internes. Le client masque certains champs, mais une lecture Firestore autorisée reçoit le document complet.

La matrice détaillée est disponible dans `docs/security/member_data_classification.md`.

### Problèmes confirmés

- **P0-SEC-002 reste ouvert** : les secrets n'ont pas encore été retirés à cette étape.
- **P0-SEC-001 reste ouvert** : aucune séparation physique ni règle locale n'a encore été modifiée.
- **P1-AUTH-001 confirmé** : plusieurs décisions de rôle/capacité dépendent encore de données locales.
- **P1-DATA-001 confirmé** : aucun `ownerUid` ne permet une règle sûre de propriétaire de fiche.

### Décision de poursuite

L'étape 2 peut retirer les codes des assets et des valeurs par défaut, supprimer les fallbacks locaux qui accordent un rôle ou une capacité, puis ajouter un test anti-secrets. La rotation/révocation distante devra rester une action humaine documentée.

### Fichiers modifiés pendant cette étape

- `docs/security/member_data_classification.md` ;
- `docs/audit/phase2_security_remediation.md` ;
- `docs/audit/preprod_changes.md`.

### Commandes et contrôles

- vérification de la branche et de `git status` ;
- recherches ciblées avec `rg` ;
- lecture des modèles `Person`/`PersonPrivacy` ;
- inspection des services d'accès et du provider d'authentification ;
- aucune commande Firebase, aucun déploiement, aucune écriture distante.

## Étape 2 — Suppression des secrets et autorisations locales

### Résumé

Les valeurs d'accès embarquées ont été supprimées des assets et modèles par défaut. Les décisions sensibles sont désormais refusées sauf lorsqu'une session Firebase authentifiée, un UID et un rôle distant vérifié sont présents. Le mode public reste disponible.

### Corrections réalisées

- `family_tree.json` ne contient plus de code d'accès, de modification ou d'administration actif.
- `AdminAccess` et `SuperAdminRecovery` sont désactivés par défaut et n'acceptent plus d'ancienne valeur désérialisée.
- `FamilyTreeData` ignore et ne sérialise plus les listes locales de codes.
- `AuthCodeService`, `ModificationCodeService`, `AdminAccessService` et `SuperAdminRecoveryService` refusent toute autorisation locale.
- `AuthController.login` et `unlockModification` n'ont plus de fallback local.
- Les permissions `AuthState` exigent un état Firebase authentifié, un UID et un rôle distant autorisé.
- Le KPI est protégé par une garde Firebase admin/superAdmin, sans dialogue de comparaison locale.
- `LocalSecurityCleanupMigration` nettoie les anciennes clés et structures JSON de façon idempotente avant chargement.
- Le scanner `tooling/security/check_secrets.dart` contrôle sources, assets et build Web en masquant les résultats.

### Fichiers fonctionnels modifiés

- `assets/data/family_tree.json`
- `lib/models/admin_access.dart`
- `lib/models/family_tree_data.dart`
- `lib/models/super_admin_recovery.dart`
- `lib/providers/auth_provider.dart`
- `lib/providers/family_tree_provider.dart`
- `lib/services/admin_access_service.dart`
- `lib/services/auth_code_service.dart`
- `lib/services/modification_code_service.dart`
- `lib/services/super_admin_recovery_service.dart`
- `lib/services/local_security_cleanup_migration.dart`
- `lib/widgets/app_shell.dart`

Les modifications antérieures de synchronisation dans `sync_service.dart` et leurs tests ont été préservées mais ne font pas partie de cette remédiation.

### Tests ajoutés ou adaptés

- refus des rôles issus de `familyCodes` ;
- refus des codes admin et récupération locaux ;
- refus d'un rôle mis en cache/ambigu ;
- autorisation admin/superAdmin uniquement avec état Firebase vérifié ;
- migration locale et idempotence ;
- contrôle du JSON généalogique et de la synchronisation existante.

### Résultats

| Contrôle | Résultat |
|---|---|
| `flutter pub get` | réussi |
| `flutter analyze` | réussi, aucun diagnostic |
| `flutter test` | réussi, 132 tests |
| scanner sources/assets | réussi |
| `flutter build web --release` | réussi |
| scanner `build/web` | réussi |
| déploiement | non exécuté |

### Occurrences restantes justifiées

- Les classes historiques de modèle et d'administration restent présentes pour compatibilité structurelle, mais leurs données sensibles ne sont plus désérialisées ou persistées.
- `familyCodes` reste un identifiant de familles liées et n'est plus une source d'authentification ou de rôle.
- `FirebaseAccessCodeAuthService` utilise encore Firebase Auth avec des comptes techniques et contrôle ensuite `user_roles`. Ce mécanisme n'est pas statique local, mais reste un P1 à remplacer par une authentification individuelle ou un échange serveur renforcé.

### Statuts

- **P0-SEC-002 : corrigé dans le dépôt actif et le build local.** La gestion d'incident reste ouverte jusqu'à révocation manuelle des anciennes valeurs et sessions.
- **P1-AUTH-001 : partiellement corrigé.** Tous les fallbacks locaux sont supprimés; le modèle distant de comptes techniques partagés reste à faire évoluer.
- **P0-SEC-001 : toujours ouvert.** La séparation physique public/privé appartient à l'étape 3.

### Risques et régressions attendues

- Les anciennes connexions uniquement locales ne fonctionnent plus, par conception.
- Un utilisateur hors ligne ou dont le rôle n'est pas vérifié conserve la consultation publique mais ne peut pas modifier ni ouvrir le KPI.
- Les administrateurs doivent disposer d'un compte Firebase actif et d'un rôle valide.

### Rollback

Un rollback du code est techniquement possible par Git, mais ne doit jamais réintroduire les anciennes valeurs. En cas de problème fonctionnel, restaurer seulement le flux Firebase et conserver la neutralisation des secrets et la migration locale.

### Verdict de l'étape

**ÉTAPE 2 VALIDÉE SOUS CONDITIONS**

Conditions : rotation/révocation manuelle, audit des rôles et sessions, puis remplacement futur des comptes techniques partagés.

## Étape 3 — Séparation physique des membres publics et privés

Architecture verrouillée le 20 juillet 2026 :

```text
families/{familyId}/members_public/{memberId}
families/{familyId}/members_private/{memberId}
```

- L'arbre charge et écoute uniquement `members_public`.
- Chaque écriture construit deux projections par liste blanche et les enregistre
  dans un même batch Firestore.
- Les coordonnées, adresses, dates complètes, notes, historique et préférences
  sont confinés à `members_private`.
- La fiche privée est chargée à la demande et ses identifiants sont vérifiés
  avant fusion avec le membre public.
- `ownerUid` n'est jamais déduit de la session : seule une valeur explicitement
  fournie par une future procédure contrôlée peut être écrite.
- Le fallback temporaire sur `members` utilise un mapper legacy à liste blanche
  stricte et ne transmet aucun champ privé à l'arbre.
- Le diagnostic Firestore cible désormais `members_public`.

Aucune migration distante, règle Firestore ou opération de déploiement n'a été
effectuée. Les règles et les tests d'émulateur restent réservés à l'étape 4.

## Étape 4 — Règles Firestore et Firebase Emulator Suite

Les règles locales protègent désormais `members_public`, `members_private`,
`user_roles` et la collection historique. Les rôles et `ownerUid` sont
server-only en écriture cliente. Le refus global final est conservé.

Résultats :

- 41 tests de règles réussis, 0 échec, avec deux familles et tous les rôles ;
- problème Windows `CreateProcessAsUserW 1312` contourné par une session normale ;
- bug `npm stdin` du binaire Firebase contourné par l'appel direct Node/Mocha ;
- index publics préparés localement ;
- aucune migration, écriture distante ou opération de déploiement.

Statuts : `P0-SEC-001` corrigé localement mais ouvert à distance,
`P1-DATA-001` ouvert et `P1-AUTH-001` partiellement corrigé.

Verdict : **ÉTAPE 4 VALIDÉE SOUS CONDITIONS**. Les conditions sont la migration
contrôlée, la revue finale, le déploiement explicite et les tests réels
post-déploiement avant préproduction.

## Étape 5 — Préparation locale de migration staging

Les étapes 1 à 10 sont terminées. Deux dry-runs locaux déterministes sont
validés avec 23 membres et aucune anomalie P0/P1. Aucun vrai projectId staging
n’étant confirmé, toutes les actions distantes restent bloquées. Aucun
`--apply`, déploiement ou compte distant n’a été créé.
