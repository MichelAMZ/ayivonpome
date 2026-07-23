# Remédiation des codes d'accès exposés

Date : 20 juillet 2026
Incident : valeurs historiques embarquées dans une ancienne version Web.

## Portée

Des codes familiaux privilégiés, de modification, d'administration et de récupération ont été trouvés dans :

- l'asset `assets/data/family_tree.json` ;
- les données de démonstration de `FamilyTreeData` ;
- les valeurs par défaut de modèles administratifs ;
- certains tests ;
- potentiellement le stockage local des navigateurs ayant chargé une ancienne version.

Les valeurs complètes ne sont pas reproduites ici. Toute valeur anciennement publiée doit être considérée compromise, même après son retrait du dépôt actif.

## Correction locale réalisée

- Asset nettoyé et structures sensibles vidées/désactivées.
- Désérialisation des anciennes listes de codes neutralisée.
- Sérialisation locale des codes administratifs/récupération supprimée.
- Valeurs par défaut sensibles supprimées.
- Autorisations locales par code supprimées.
- Migration idempotente de nettoyage des préférences et JSON local ajoutée.
- Scanner anti-secrets ajouté pour les sources, assets et build Web.

## Actions manuelles obligatoires

- [ ] Identifier tous les comptes Firebase techniques associés aux anciens codes.
- [ ] Réinitialiser leurs mots de passe avec des valeurs uniques et fortes.
- [ ] Révoquer les sessions et jetons de rafraîchissement existants.
- [ ] Contrôler `user_roles` et désactiver tout utilisateur inconnu ou injustifié.
- [ ] Vérifier particulièrement les rôles `admin` et `superAdmin`.
- [ ] Examiner les journaux Auth/Firestore depuis la première publication exposée.
- [ ] Purger les anciens canaux de prévisualisation Firebase Hosting concernés.
- [ ] Vérifier la politique de rétention des anciennes versions Hosting.
- [ ] Informer les administrateurs légitimes sans transmettre de nouveau secret par canal non sécurisé.
- [ ] Interdire la réutilisation d'une ancienne valeur ou d'une variante prévisible.

## Vérification après révocation

1. Confirmer qu'une tentative avec chaque ancienne valeur échoue dans Firebase Auth.
2. Confirmer que les comptes techniques attendus ont une date de rotation récente.
3. Confirmer que les sessions antérieures sont invalidées.
4. Confirmer qu'un utilisateur sans rôle actif ne peut ni écrire ni ouvrir le KPI.
5. Exécuter `dart run tooling/security/check_secrets.dart --include-build`.
6. Vérifier manuellement l'asset publié et les anciennes previews encore accessibles.

## Prévention

- Ne jamais utiliser un asset, une constante Dart ou un stockage local comme autorité.
- Firebase Auth identifie l'utilisateur; `user_roles/{uid}` et les règles déterminent ses droits.
- Utiliser un projet Firebase staging distinct pour les essais.
- Exécuter le scanner dans la future CI.
- Faire auditer et limiter le débit de tout futur mécanisme ergonomique par code côté serveur.
