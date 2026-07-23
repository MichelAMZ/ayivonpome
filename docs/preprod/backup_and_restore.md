# Sauvegarde et restauration staging

La source locale du dry-run est sauvegardée sous
`backups/preprod/20260720T181800Z/`, dossier exclu de Git. Son manifeste contient
le SHA-256 `4C8E2471BDEC1EB4DF34E38C6A02D095F2FF41B5610D35B434542F3B4FFDFFA4`.

Avant une migration distante, exporter séparément les collections source,
relations, rôles staging et paramètres, vérifier les compteurs et checksums,
puis marquer explicitement la sauvegarde validée. Ne jamais placer un export
privé dans Git.

La restauration doit viser uniquement le projectId staging explicite, être
précédée d’un dry-run, restaurer données puis règles antérieures et être validée
par comparaison des compteurs. Aucun rollback distant n’a été testé à cette
étape, faute de projet staging.
