# Plan de rollback staging

1. Bloquer les accès au canal Hosting staging.
2. Suspendre la migration et conserver checkpoint, rapports et logs.
3. Exporter l’état fautif pour analyse.
4. Restaurer le snapshot staging validé et les règles précédentes.
5. Désactiver les comptes de test concernés.
6. Comparer compteurs, relations et checksums.
7. Corriger, refaire deux dry-runs puis obtenir une nouvelle validation humaine.

La collection legacy ne doit pas être supprimée. Le canal Hosting devra être
supprimé seulement après conservation des preuves. Ce plan reste à tester sur
un vrai staging et bloque le GO PREPROD.
