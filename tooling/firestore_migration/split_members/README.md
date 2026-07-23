# Migration split members

L’outil est un analyseur local et fonctionne en dry-run par défaut. Il accepte
`--dry-run`, `--apply`, `--source-project`, `--target-project`, `--family-id`,
`--limit`, `--resume-from`, `--output` et `--confirm-staging`.

Dans cette étape, `--apply` est systématiquement refusé, même si les autres
conditions sont fournies. Les rapports JSON/Markdown sont écrits uniquement
dans `migration_output/`, exclu de Git.
