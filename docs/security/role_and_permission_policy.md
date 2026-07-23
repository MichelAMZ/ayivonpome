# Politique des rôles et permissions

## Source d'autorité

Firebase Authentication fournit l'identité. Le document
`user_roles/{request.auth.uid}` fournit l'autorisation avec les champs réels :

```json
{
  "uid": "firebase-uid",
  "role": "member | editor | admin | superAdmin",
  "familyIds": ["familyA"],
  "active": true
}
```

Un rôle fourni dans un membre, une requête ou l'état Flutter n'est jamais une
source d'autorité. Un document absent, inactif, incohérent avec l'UID ou avec un
rôle inconnu ne donne aucun droit.

Les appels `get/exists` du document de rôle sont mis en cache au cours d'une
même évaluation de règles, mais restent soumis aux quotas et limites Firestore.
Les règles évitent de lire les documents de rôle pour les lectures réellement
publiques de `members_public`.

## Permissions

- `member` : lecture familiale autorisée et lecture de sa fiche privée si
  `ownerUid` correspond ; aucune administration.
- `editor` : écritures collaboratives non sensibles existantes, sans accès
  administratif aux fiches privées.
- `admin` : administration des membres publics/privés de ses `familyIds`.
- `superAdmin` : lecture publique et privée globale et administration des
  familles, mais aucune écriture cliente dans `user_roles`.

Toutes les créations, promotions, désactivations et suppressions de rôle sont
server-only ou manuelles. Un utilisateur ne modifie jamais son propre rôle. Un
admin ne crée ni ne promeut un superAdmin.

## Politique `ownerUid`

`ownerUid` est nullable. `null` ou l'absence du champ représente une fiche non
revendiquée et ne confère aucun droit propriétaire.

Le client ne peut ni attribuer ni modifier `ownerUid`, même avec un rôle admin.
L'attribution initiale devra utiliser une Cloud Function privilégiée, un outil
d'administration sécurisé ou une opération manuelle contrôlée qui vérifie
l'appartenance familiale et journalise l'action.

Le propriétaire peut modifier uniquement ses champs personnels privés. Il ne
peut changer `familyId`, `memberId`, `ownerUid`, `createdAt`, les métadonnées
administratives ou supprimer sa fiche.

## Politique superAdmin

Le superAdmin peut lire toutes les données publiques et privées pour une
opération administrative justifiée et administrer les documents familiaux.
Il ne peut pas modifier son rôle ni créer un autre superAdmin depuis le client.
Les futures interfaces doivent exiger un motif et créer une trace d'audit avant
toute consultation privée globale.
