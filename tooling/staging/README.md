# Données de staging

L’anonymiseur fonctionne localement, en mode dry-run par défaut, ne remplace
jamais sa source et refuse toute cible production. Il conserve les identifiants
et relations, masque les champs privés et marque le jeu comme staging.

```powershell
dart run tooling/staging/anonymize_members.dart `
  --input assets/data/family_tree.json `
  --output migration_output/staging_anonymized.json `
  --report migration_output/anonymization_report.json
```

L’option `--apply` est volontairement refusée dans cette version : aucune
écriture distante n’est autorisée avant validation humaine du dry-run.
