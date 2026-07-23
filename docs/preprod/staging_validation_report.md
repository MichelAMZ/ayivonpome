# Rapport de validation staging — préparation locale

Verdict des dry-runs : **DRY-RUN VALIDÉ**.

| Mesure | Run 1 | Run 2 |
|---|---:|---:|
| Membres | 23 | 23 |
| Publics projetés | 23 | 23 |
| Privés projetés | 23 | 23 |
| P0 / P1 | 0 / 0 | 0 / 0 |
| Avertissements | 2 | 2 |
| Digest | `65d8baf1730f6ce0` | `65d8baf1730f6ce0` |

Les SHA-256 des rapports et manifestes sont identiques. Les avertissements
signalent uniquement l’absence de staging configuré et l’absence volontaire de
contrôle distant des conflits. Aucun `--apply`, déploiement, compte, Hosting ou
rollback distant n’a été exécuté.

Verdict global : **NO-GO PREPROD** jusqu’à confirmation d’un vrai projectId
staging, sauvegarde distante, migration contrôlée et recette complète.
