# Audit code-first progressif - AYIVON

## Etat actuel

- `Person` est le modele principal de membre et contient a la fois les champs canoniques `fatherId`, `motherId`, `spouseIds`, `childrenIds` et les champs historiques `parents`, `spouses`, `children`.
- `MarriageRelation` porte les unions, y compris le mariage traditionnel, mais certains anciens champs de `Person` restent utilises pour l'affichage et la compatibilite.
- `FamilyTreeData` est la racine locale JSON et contient aussi la file `pendingSyncQueue`.
- Firestore est isole principalement dans `FirestoreRemoteDatabaseClient`, avec `members`, `relationships`, `family_tree_links`, `sync_incidents`.
- La base locale est geree par `LocalJsonRepository` et les services de stockage JSON.
- `SyncService` transforme les modifications locales en `PendingSyncItem` et synchronise vers Firestore.
- `FamilyTreeNotifier` orchestre l'etat Riverpod, la sauvegarde locale, la synchronisation et le recalcul.
- `FamilyTreeCanvas` reconstruit l'arbre a partir de `FamilyTreeData`, `fatherId`, `motherId`, `parents`, `spouseIds`, `spouses` et `MarriageRelation`.
- Les regles Firestore controlent `familyId`, les roles `user_roles`, et imposent `version == resource.version + 1` sur `members`.

## Incoherences et risques constates

- Les relations parent-enfant sont stockees en double : `fatherId/motherId` et `parents`, puis `childrenIds` et `children`.
- Les unions sont aussi stockees en double pendant la transition : `MarriageRelation` et `spouseIds/spouses`.
- Les anciennes actions UI pouvaient construire une relation dans un widget puis appeler une sauvegarde generique, ce qui risquait d'oublier les operations de synchronisation.
- `schemaVersion` n'est pas encore present sur les documents metier principaux ; il faut l'ajouter via migration non destructive.
- Les operations de synchronisation representent encore souvent des documents (`person`, `marriage`) plutot qu'une intention metier complete (`linkFather`, `createUnion`).

## Premiere etape appliquee

Le parcours prioritaire est limite a :

`Pere -> Lier une personne existante`

Il sert de modele code-first progressif :

- un enum metier `ParentRole` ;
- des erreurs metier explicites ;
- un service domaine `FamilyRelationshipService` sans dependance Flutter/Firebase ;
- un cas d'utilisation `LinkExistingFatherUseCase` ;
- une orchestration dans `FamilyTreeNotifier` qui prepare les versions, met a jour l'etat local et ajoute les operations de synchronisation.

## Migrations

Aucune migration destructive n'est executee dans cette etape.

La lecture reste compatible avec les anciens champs `parents`, `children`, `spouses` et `spouseIds`.
