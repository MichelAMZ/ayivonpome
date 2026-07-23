# Revue de sécurité Firestore — phase 2, étape 4

Date : 20 juillet 2026
Branche : `audit/preprod-readiness`
Portée : règles et tests locaux uniquement.

## Constats initiaux

Les règles précédentes rendaient les documents historiques `members` publics
pour Ayivon. Elles ne connaissaient pas `members_public` et `members_private`.
Un `superAdmin` pouvait écrire directement dans `user_roles`, y compris sur son
propre document. Les notifications Ayivon étaient également publiques.

Le refus global existait déjà, mais ne compensait pas ces autorisations plus
spécifiques. Les fonctions de rôle reposaient sur le document distant
`user_roles/{uid}` et sur le contrat réel `active + role + familyIds`.

## Architecture locale obtenue

- `families/{familyId}/members_public/{memberId}` : lecture publique, écriture
  admin de la famille ou superAdmin, schéma public version 2 strict.
- `families/{familyId}/members_private/{memberId}` : aucune lecture anonyme,
  lecture propriétaire/admin même famille ou superAdmin, écritures bornées.
- `members/{memberId}` : lecture de migration admin même famille/superAdmin,
  aucune écriture.
- `user_roles/{uid}` : lecture propre, admin borné à sa famille ou superAdmin ;
  toutes les écritures clientes sont refusées.
- refus global final pour tout chemin non déclaré.

Les règles vérifient la cohérence chemin/payload, `schemaVersion == 2`, les
champs obligatoires, les types principaux, les tailles, les clés autorisées,
`updatedAt == request.time` et l'immuabilité des identifiants. Une date
`createdAt` existante reste immuable.

## Collections protégées

| Collection | Anonyme | Membre | Admin famille | SuperAdmin | Écriture cliente |
|---|---|---|---|---|---|
| `members_public` | lecture | lecture | lecture/écriture | lecture/écriture | liste blanche |
| `members_private` | refus | propriétaire seulement | même famille | globale | liste blanche |
| `user_roles` | refus | rôle propre | rôles même famille | lecture globale | refus total |
| `members` legacy | refus | refus | migration même famille | lecture | refus total |
| `activity_logs` | refus | refus | même famille | globale | création bornée, pas d'update |
| `notifications` | refus | même famille | même famille | globale | bornée à la famille |
| `announcements` | refus | même famille | même famille | globale | bornée à la famille |
| `settings` | refus | refus | même famille | globale | admin/superAdmin |

`relationships` et `family_tree_links` conservent une lecture publique pour les
données Ayivon nécessaires à l'arbre ; leurs écritures exigent un rôle distant
actif et une famille cohérente.

## Tests Emulator Suite

Framework : `@firebase/rules-unit-testing`, Firebase JS SDK et Mocha. Projet
de démonstration local : `demo-ayivon-preprod`.

Résultat : **41 tests réussis, 0 échec**. Les scénarios couvrent anonyme,
membre, propriétaire, admin de deux familles, superAdmin, rôle inactif et rôle
absent ; champs privés interdits dans le public ; ownership nullable ;
immutabilité ; rôles server-only ; isolation des logs, notifications et
paramètres ; requêtes collection-group ; legacy ; requêtes et index applicatifs.

## Index locaux

Trois index `members_public` ont été préparés :

- `deletedAt + displayOrder` ;
- `isDeceased + displayOrder` ;
- `isPatriarch + displayOrder`.

Ils ne sont pas déployés.

## Limites et risques restants

- Aucune règle n'est déployée : l'environnement distant reste vulnérable selon
  les anciennes règles actuellement actives.
- Les anciennes données ne sont pas migrées et `P1-DATA-001` reste ouvert.
- La création/rotation des rôles et l'attribution de `ownerUid` nécessitent un
  processus serveur ou manuel sécurisé.
- Une lecture superAdmin du privé est techniquement permise ; la justification
  et la journalisation métier restent à implémenter.
- Les listes valident leur taille mais pas chaque élément individuellement ; ce
  durcissement peut être ajouté après validation de compatibilité des données.
- `npm install` signale 3 vulnérabilités dans l'outillage de test uniquement ;
  aucune dépendance n'est embarquée dans Flutter.

## Statuts

- `P0-SEC-001` : **corrigé localement**, encore ouvert à distance.
- `P1-DATA-001` : ouvert, migration distante non réalisée.
- `P1-AUTH-001` : partiellement corrigé ; rôles protégés côté règles locales,
  mais le cycle d'administration serveur reste à construire.

Verdict : **ÉTAPE 4 VALIDÉE SOUS CONDITIONS**. Conditions : migration contrôlée,
revue finale des règles, déploiement explicite et tests post-déploiement avant
préproduction.
