# Préparation préproduction

Verdict actuel : **NO-GO PREPROD**.

`P0-SEC-001` est corrigé localement mais les règles ne sont pas déployées.
`P1-DATA-001` reste ouvert car aucune donnée staging n’est migrée.
`P1-AUTH-001` reste partiellement corrigé car les comptes individuels et le
processus serveur de rôles ne sont pas validés.

Les règles émulateur, tests Flutter, build et deux dry-runs locaux sont validés.
Les prérequis manquants sont : vrai projet staging, sauvegarde distante,
migration, validation post-migration, règles/index staging, comptes multi-rôles,
Hosting staging, tests Web/Android réels et rollback testé.
