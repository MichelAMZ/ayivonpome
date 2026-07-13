# Déploiement LWS PHP/MySQL

Ce projet reste une application Flutter Web côté interface et ajoute un socle API REST PHP/MySQL compatible hébergement mutualisé LWS.

## Architecture

- Frontend Flutter Web : `build/web/`
- API PHP : `api/public/index.php`
- Migrations MySQL : `api/migrations/`
- Import JSON : `api/scripts/import_json.php`
- Codes initiaux hashés : `api/scripts/seed_access_codes.php`

## Préparer la base LWS

1. Créer une base MySQL/MariaDB depuis le panel LWS.
2. Créer un utilisateur MySQL et noter `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
3. Importer dans phpMyAdmin, dans cet ordre :
   - `api/migrations/001_initial_schema.sql`
   - `api/migrations/002_indexes.sql`
   - `api/migrations/003_seed_data.sql`

## Configurer l’API

1. Copier `api/.env.example` vers `api/.env` sur le serveur.
2. Renseigner les valeurs de production :

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.mondomaine.fr
DB_HOST=localhost
DB_PORT=3306
DB_NAME=nom_base
DB_USER=nom_utilisateur
DB_PASSWORD=mot_de_passe
FRONTEND_URL=https://mondomaine.fr,https://www.mondomaine.fr
SESSION_SECRET=une_valeur_longue_aleatoire
BACKUP_PATH=../storage/backups
```

3. Ne jamais publier le vrai fichier `.env`.
4. Pointer le document root du sous-domaine API vers `api/public/`.
5. Vérifier que `api/public/.htaccess` est bien uploadé.

## Initialiser les codes d’accès

Les codes ne doivent jamais être stockés en clair dans MySQL.

Ajouter temporairement dans `api/.env` sur le serveur :

```env
INITIAL_FAMILY_ID=family-ayivon
INITIAL_FAMILY_CODE=ayivon
INITIAL_ADMIN_CODE=ayivonvi2026
INITIAL_RECOVERY_CODE=Aziangbédévi2026!
```

Exécuter :

```bash
php api/scripts/seed_access_codes.php
```

Supprimer ensuite ces quatre variables du `.env` de production.

## Importer les données JSON existantes

Après la création du schéma :

```bash
php api/scripts/import_json.php assets/data/family_tree.json
```

Le script conserve les IDs existants, importe les familles/personnes, convertit `fatherId` et `motherId` vers `parent_child_relations`, et convertit `marriageRelations` vers `marriage_relations`.

## Builder Flutter Web

Compiler avec l’URL de l’API :

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.mondomaine.fr/api
```

Uploader le contenu de `build/web/` vers `public_html/` ou le dossier du domaine principal.

Le fichier `web/.htaccess` permet aux routes Flutter Web de fonctionner après rechargement direct.

## Tester

Tester l’API :

```text
GET https://api.mondomaine.fr/api/health
```

Réponse attendue :

```json
{
  "success": true,
  "data": {
    "api": "online",
    "database": "connected"
  }
}
```

Tester ensuite :

- authentification par code ;
- chargement des familles ;
- chargement des personnes ;
- import/export JSON ;
- synchronisation `sync/push` et `sync/pull` ;
- consultation hors ligne puis retour réseau.

## Sécurité

- Flutter ne se connecte jamais directement à MySQL.
- Les accès MySQL restent uniquement dans `api/.env`.
- Les codes sont validés avec `password_verify()`.
- Les requêtes SQL utilisent PDO préparé.
- Les suppressions métier utilisent `deleted_at` quand pertinent.
- CORS doit lister explicitement le domaine frontend, pas `*` en production.

## Limites de cette première base

Le socle API, SQL, scripts et couche Flutter sont prêts. Les écrans existants continuent d’utiliser le stockage actuel tant que les providers ne sont pas basculés vers les nouveaux repositories `lib/data`. Les contrôleurs admin avancés, fusion de familles, upload photo complet et résolution UI de conflits doivent être branchés dans une passe dédiée.

