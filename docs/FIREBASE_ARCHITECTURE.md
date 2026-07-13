# Architecture Firebase

Ce socle garde le JSON local comme source active par defaut, puis permet
d'activer Firestore lorsque le projet Firebase est configure.

## Activation

1. Creer le projet Firebase.
2. Installer les outils Firebase et FlutterFire.
3. Generer la configuration FlutterFire ou passer les valeurs via
   `--dart-define`.
4. Deployer `firestore.rules` et `firestore.indexes.json`.
5. Lancer l'application avec `ENABLE_FIREBASE=true`.

Exemple web :

```bash
flutter build web --release \
  --dart-define=ENABLE_FIREBASE=true \
  --dart-define=FIREBASE_TRUSTED_DEVICE=false \
  --dart-define=FIREBASE_FAMILY_ID=ayivon \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

## Collections

- `families`
- `members`
- `relationships`
- `family_tree_links`
- `notifications`
- `activity_logs`
- `users`

Chaque document metier porte `familyId` pour isoler les familles et preparer
le fonctionnement multi-tenants.

## Hors connexion

Le cache persistant Firestore est conditionne par
`FIREBASE_TRUSTED_DEVICE=true`. Sur ordinateur partage, il doit rester a
`false` tant que l'utilisateur n'a pas explicitement confirme que l'appareil est
fiable.

## Conflits

Les membres portent `version`, `updatedAt` et `updatedBy`. Le client Firestore
refuse une mise a jour si la version distante est plus recente que la version
locale. Les regles Firestore imposent aussi l'incrementation de version pour les
membres.

## JSON

Le fichier JSON reste utile pour :

- l'import initial ;
- l'export de sauvegarde ;
- les tests locaux ;
- la reprise si Firebase n'est pas encore configure.
