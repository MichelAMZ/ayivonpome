# Projets Firebase

| Environnement | ProjectId | Usage |
|---|---|---|
| Production | `ayivon-aziangbede` | Application publique actuelle ; interdite pendant les essais de migration. |
| Staging | **non fourni / non validé** | Doit être créé ou confirmé avant toute commande distante. |
| Émulateur | `demo-ayivon-preprod` | Tests locaux uniquement ; tout service non émulé échoue. |

`.firebaserc` conserve la production comme `default` et expose `production` et
`emulator`. Aucun alias `staging` n’est ajouté tant que son projectId réel n’est
pas confirmé. Toute future commande staging devra inclure explicitement
`--project <staging-project-id>`. Les commandes de migration ou déploiement vers
`production`, `default` ou le projectId de production sont interdites avant une
autorisation humaine dédiée.
