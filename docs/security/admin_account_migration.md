# Migration des comptes administrateurs

Chaque administrateur doit utiliser un compte Firebase individuel et un rôle
lié à son UID. Les emails génériques, comptes partagés et mots de passe communs
sont interdits. La création et la modification de `user_roles` restent
server-only.

Le staging devra inventorier les comptes partagés sans exposer leurs secrets,
créer des comptes individuels, tester désactivation/récupération et MFA si
disponible, puis journaliser chaque affectation. Les anciens comptes ne seront
révoqués en production qu’après validation humaine du basculement.

`P1-AUTH-001` reste ouvert : aucun compte staging réel n’a été créé ou testé.
