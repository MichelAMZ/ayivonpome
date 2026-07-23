# Validation de migration de l’arbre

Source locale validée : 23 membres. Les deux dry-runs conservent les 23 IDs,
parents, enfants, conjoints et générations, sans doublon, relation cassée ou
cycle. Ils produisent 23 projections publiques et 23 privées avec
`schemaVersion: 2`, `ownerUid: null` et aucune clé privée dans le public.

Digest déterministe des projections : `65d8baf1730f6ce0`.

La vérification réelle du patriarche, des photos, de l’ordre Firestore, des
documents déjà migrés et des conflits nécessite le projet staging. Elle reste
obligatoire après migration et n’est pas déclarée réussie ici.
