# Sprint 0 - Refonte de l'architecture

## Objectif

Stabiliser définitivement Ayivonpome avant toute nouvelle fonctionnalité métier.

Le projet passe d'une application Flutter centrée sur un fichier JSON à une plateforme collaborative de généalogie, multi-familles et compatible LWS :

- Flutter Web pour l'interface ;
- API REST PHP sur LWS ;
- MySQL/MariaDB comme source officielle ;
- cache local pour le mode hors ligne ;
- JSON réservé à l'import, l'export, la sauvegarde et la restauration ;
- isolation multi-tenants par `family_id`.

## Gel fonctionnel

Pendant ce sprint, aucune nouvelle fonctionnalité métier n'est ajoutée sauf si elle est nécessaire à la migration d'architecture.

Priorités autorisées :

- sécurité ;
- migration des données ;
- architecture ;
- tests ;
- déploiement ;
- correction de régressions bloquantes.

## Architecture cible

```text
Internet
  |
Nom de domaine
  |
https://famille-ayivon.com
  |
Flutter Web (LWS)
  |
  +-- JSON Cache / Offline
  |     |
  |     +-- IndexedDB (Web)
  |     +-- SQLite (Android/Desktop)
  |
  +-- API REST PHP
  |     |
  |     +-- MySQL / MariaDB
  |     +-- Sauvegardes JSON
  |
  +-- Administration / KPI
```

## Principes non négociables

- Flutter ne se connecte jamais directement à MySQL.
- Toute lecture distante passe par l'API REST.
- Toute écriture distante passe par l'API REST.
- MySQL/MariaDB est la source officielle en mode production.
- Le JSON n'est plus la source officielle en mode database/hybrid.
- Chaque donnée métier doit porter un `family_id` quand elle appartient à une famille.
- Les suppressions métier utilisent `deleted_at` quand l'historique doit être conservé.
- Les codes d'accès sont hashés côté serveur.
- Les conflits de synchronisation ne sont jamais écrasés silencieusement.
- Le projet reste utilisable hors ligne en consultation.

## Multi-tenancy

La plateforme doit pouvoir héberger plusieurs familles dans la même base :

- Famille AYIVON ;
- Famille LEVONVI ;
- Famille AMOUZOU ;
- Famille KOFFI ;
- autres familles, clans, villages, associations ou diasporas.

Chaque famille possède :

- son arbre ;
- ses administrateurs ;
- ses codes ;
- son conseil familial ;
- son historique ;
- ses notifications ;
- ses sauvegardes ;
- ses journaux d'audit.

Le Super Admin plateforme peut gérer toutes les familles selon des règles strictes d'audit et de sécurité.

## Découpage en couches

```text
lib/
  presentation/  UI, widgets, screens
  domain/        entités, règles métier, cas d'usage
  data/          repositories, DTO, mappers, local/remote stores
  infrastructure/config, réseau, stockage, sync, sécurité
```

L'organisation actuelle peut être migrée progressivement. Le sprint 0 doit éviter un big bang risqué.

## Phases et tâches

### Phase 1 - Architecture générale

1. Geler les nouvelles fonctionnalités métier.
2. Définir les couches `presentation`, `domain`, `data`, `infrastructure`.
3. Cartographier les fichiers existants par couche cible.
4. Identifier les dépendances interdites entre couches.
5. Centraliser la configuration applicative.
6. Centraliser la configuration API.
7. Centraliser les constantes métier.
8. Définir les environnements `development`, `test`, `production`.
9. Ajouter une convention de nommage des fichiers.
10. Définir le modèle d'injection de dépendances avec Riverpod.
11. Créer une stratégie de migration progressive des providers.
12. Définir les erreurs métier standardisées.

### Phase 2 - Base de données

13. Valider le schéma `families`.
14. Valider le schéma `people`.
15. Valider le schéma `parent_child_relations`.
16. Valider le schéma `marriage_relations`.
17. Valider le schéma `family_tree_links`.
18. Valider le schéma `admins`.
19. Valider le schéma `access_codes`.
20. Valider le schéma `notifications`.
21. Valider le schéma `audit_logs`.
22. Valider le schéma `sync_operations`.
23. Ajouter les index critiques.
24. Ajouter les contraintes d'intégrité.
25. Vérifier `utf8mb4`.
26. Vérifier `InnoDB`.
27. Préparer les migrations incrémentales.
28. Préparer une stratégie de rollback.

### Phase 3 - API REST PHP

29. Stabiliser le routeur PHP.
30. Stabiliser `GET /api/health`.
31. Stabiliser le format de réponse succès.
32. Stabiliser le format de réponse erreur.
33. Ajouter les middlewares CORS.
34. Ajouter l'authentification par token opaque.
35. Ajouter la validation des rôles.
36. Ajouter la validation des payloads.
37. Ajouter le CRUD familles.
38. Ajouter le CRUD personnes.
39. Ajouter le CRUD relations parent-enfant.
40. Ajouter le CRUD mariages/divorces.
41. Ajouter les endpoints arbres liés.
42. Ajouter les endpoints historiques.
43. Ajouter les endpoints conseil familial.
44. Ajouter les endpoints notifications.
45. Ajouter les endpoints bugs.
46. Ajouter les endpoints KPI admin.
47. Ajouter les endpoints backups.
48. Ajouter les endpoints import/export.

### Phase 4 - Migration des données

49. Lire le JSON existant.
50. Valider le schéma JSON.
51. Détecter les personnes sans ID.
52. Détecter les IDs dupliqués.
53. Créer les familles manquantes.
54. Importer les personnes.
55. Convertir `fatherId`.
56. Convertir `motherId`.
57. Convertir `parents`.
58. Convertir `childrenIds`.
59. Convertir `spouseIds`.
60. Convertir `marriageRelations`.
61. Importer les historiques.
62. Importer le conseil familial.
63. Importer les paramètres.
64. Importer les notifications.
65. Générer un rapport d'import.
66. Créer une sauvegarde avant import.

### Phase 5 - Mode hors ligne

67. Choisir IndexedDB pour Flutter Web.
68. Choisir SQLite pour Android/iOS/Desktop.
69. Isoler le stockage local derrière une interface.
70. Stocker le cache des familles.
71. Stocker le cache des personnes.
72. Stocker le cache des relations.
73. Stocker le cache des mariages.
74. Stocker les paramètres.
75. Stocker la file d'attente.
76. Afficher l'état hors ligne.
77. Autoriser la consultation hors ligne.
78. Empêcher les écritures dangereuses sans file d'attente.

### Phase 6 - Synchronisation

79. Définir `PendingSyncOperation`.
80. Ajouter `deviceId`.
81. Ajouter `baseVersion`.
82. Envoyer les opérations en attente.
83. Récupérer les changements distants.
84. Appliquer les changements localement.
85. Marquer les opérations synchronisées.
86. Gérer les erreurs réseau.
87. Rejouer automatiquement au retour Internet.
88. Détecter les conflits de version.
89. Créer `ConflictResolutionDialog`.
90. Auditer les synchronisations.

### Phase 7 - Sauvegardes

91. Créer export JSON complet.
92. Créer export SQL optionnel.
93. Lister les sauvegardes.
94. Restaurer une sauvegarde.
95. Restreindre la restauration au Super Admin.
96. Sauvegarder avant import.
97. Sauvegarder avant suppression massive.
98. Sauvegarder avant fusion de familles.

### Phase 8 - Sécurité

99. Hasher tous les codes d'accès.
100. Supprimer tout stockage de code en clair côté serveur.
101. Limiter les tentatives de codes.
102. Journaliser les échecs d'authentification.
103. Sécuriser les sessions.
104. Restreindre CORS en production.
105. Valider tous les inputs API.
106. Utiliser uniquement PDO préparé.
107. Vérifier les permissions côté serveur.
108. Auditer les actions admin.

### Phase 9 - Performance

109. Ajouter pagination des historiques.
110. Ajouter chargement progressif des branches.
111. Optimiser les requêtes arbre.
112. Mettre en cache les familles.
113. Mettre en cache les KPI.
114. Réduire les payloads de sync.
115. Mesurer le rendu des grands arbres.

### Phase 10 - Déploiement LWS

116. Finaliser `.env.example`.
117. Finaliser `.htaccess` API.
118. Finaliser `.htaccess` Flutter Web.
119. Documenter le build `flutter build web`.
120. Documenter l'upload `build/web`.
121. Documenter le sous-domaine API.
122. Documenter l'import SQL via phpMyAdmin.
123. Tester HTTPS.
124. Tester `/api/health`.

### Phase 11 - Tests

125. Ajouter tests unitaires API.
126. Ajouter tests auth API.
127. Ajouter tests rôles API.
128. Ajouter tests migration JSON.
129. Ajouter tests repositories Flutter.
130. Ajouter tests offline queue.
131. Ajouter tests sync push/pull.
132. Ajouter tests conflits.
133. Ajouter tests KPI.
134. Ajouter tests build web.
135. Ajouter tests de non-régression UI.

## Critères de validation Sprint 0

- `flutter analyze` passe.
- `flutter test` passe.
- `flutter build web --release --dart-define=API_BASE_URL=...` passe.
- Le schéma SQL s'importe sur MySQL/MariaDB.
- `/api/health` retourne `api=online` et `database=connected`.
- Les codes initiaux sont hashés, jamais stockés en clair.
- Le JSON existant peut être importé avec rapport.
- L'application peut charger les données depuis le cache local.
- La documentation LWS est exploitable par un déploiement réel.

## Hors périmètre Sprint 0

- Nouvelles pages métier non nécessaires à l'architecture.
- Refonte graphique complète.
- Monétisation.
- Marketplace.
- Gestion commerciale SaaS.

Ces sujets pourront être planifiés après stabilisation de l'architecture.
