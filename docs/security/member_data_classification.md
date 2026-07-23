# Classification des données d'un membre

Date : 20 juillet 2026
Statut : proposition issue de l'étape 1 de la phase 2; aucune migration distante effectuée.

## Principes

Firestore renvoie tous les champs d'un document dont la lecture est autorisée. Les indicateurs de visibilité appliqués uniquement dans Flutter ne protègent donc pas les champs stockés dans un document public.

La classification retient cinq niveaux :

- **Public** : nécessaire à l'arbre consultable sans authentification.
- **Famille** : accessible uniquement à un utilisateur Firebase actif appartenant à la famille.
- **Administrateur** : accessible à un administrateur de la famille; le super administrateur suit la même politique sauf besoin documenté.
- **Propriétaire** : accessible à la personne liée au profil, si un futur `ownerUid` vérifiable est ajouté.
- **Jamais public** : ne doit jamais être présent dans un document lisible anonymement.

Le modèle actuel ne possède pas de `ownerUid`. Une politique « propriétaire de la fiche » ne peut donc pas encore être appliquée de façon sûre.

## Matrice du modèle `Person`

| Champ actuel | Sensibilité | Visibilité autorisée | Emplacement cible | Justification |
|---|---|---|---|---|
| `id` | faible | public | document public | Identifiant nécessaire au graphe. |
| `familyId` | faible/interne | public | document public, immuable | Nécessaire au cloisonnement et aux règles. |
| `firstName`, `lastName` | personnelle | public | document public | Identité minimale affichée dans l'arbre. |
| `gender` | personnelle | public seulement si consenti | document public projeté | Déjà contrôlé par un indicateur de visibilité. |
| `photo` | personnelle | public seulement si consenti | document public projeté | Doit pouvoir être omis sans casser l'UI. |
| `generation` | faible | public | document public | Nécessaire à la disposition de l'arbre. |
| `fatherId`, `motherId` | personnelle | public seulement selon politique familiale | document public projeté | Nécessaire au graphe si l'arbre est public. |
| `spouseIds`, `childrenIds` | personnelle | public seulement selon politique familiale | document public projeté | Relations généalogiques visibles. |
| `parents`, `spouses`, `children` | personnelle | public seulement selon politique familiale | document public projeté | Doublons techniques des relations; à normaliser. |
| `publicMapLocation` | personnelle modérée | public si volontairement général | document public projeté | Ne doit contenir aucune adresse précise. |
| année de naissance dérivée | personnelle modérée | public si consenti | `birthYear` public | Préférer l'année à la date complète. |
| `birthDate` | sensible | famille ou propriétaire; public uniquement consentement explicite | profil privé | Une date complète facilite l'identification. |
| `deathDate` | personnelle | public si consenti | public projeté ou privé | Politique explicite requise. |
| `birthLastName`, `originalLastName` | personnelle | famille; public si consenti | profil privé, projection facultative | Peut révéler filiation et identité antérieure. |
| `birthPlace`, `birthCity`, `birthCountry` | personnelle | famille; projection publique facultative et générale | profil privé | Lieu détaillé non requis au graphe public. |
| `deathPlace`, `burialPlace` | personnelle | famille; public si consenti | profil privé, projection facultative | Peut être sensible pour les proches. |
| `currentCity`, `currentRegion`, `currentCountry` | sensible | famille ou propriétaire | profil privé | Localisation actuelle. |
| `currentAddress` | très sensible | propriétaire et administrateur selon besoin | profil privé | Jamais public. |
| `latitude`, `longitude` | très sensible | propriétaire; admin si besoin justifié | profil privé | Géolocalisation précise, jamais publique par défaut. |
| `importantPlaces` | sensible | famille ou propriétaire | profil privé | Peut contenir des lieux et coordonnées détaillés. |
| `email` | très sensible | propriétaire; famille selon consentement | profil privé | Donnée de contact, jamais dans le document public. |
| `phoneNumber`, `whatsappNumber` | très sensible | propriétaire; famille selon consentement | profil privé | Données de contact directes. |
| `allowContact` | privée | famille/propriétaire | profil privé | Préférence personnelle. |
| `emailVisibility`, `phoneVisibility`, `whatsappVisibility` | privée/interne | famille/propriétaire | profil privé | Politique de divulgation. |
| `privacy` | privée/interne | famille/propriétaire; projection minimale publique | profil privé | La configuration complète révèle les choix de confidentialité. |
| `history` | sensible | famille ou administrateur selon contenu | profil privé | Peut contenir événements, dates et lieux. |
| `notes` | très sensible | propriétaire/admin selon finalité | profil privé | Texte libre susceptible de contenir toute donnée. |
| `familyCode`, `originFamilyId` | interne | famille | profil privé ou référence contrôlée | Ne doit jamais être assimilé à un secret d'accès. |
| `linkedTreeEnabled` | interne | famille/admin | profil privé | Configuration technique. |
| `marriageType` | personnelle | famille; public seulement si politique explicite | profil privé | Information familiale potentiellement sensible. |
| `createdAt`, `updatedAt` | interne | famille/admin | profil privé ou métadonnées internes | Audit et conflits, inutiles au visiteur. |
| `createdBy`, `updatedBy` | très sensible/interne | administrateur | profil privé/admin | Identifiant technique d'un utilisateur. |
| `version` | interne | famille/admin | profil privé ou métadonnées internes | Contrôle de concurrence. |
| `deletedAt` | interne | administrateur | profil privé/admin | Cycle de vie et suppression logique. |
| `isTemporaryProfile`, `profileNeedsCompletion` | interne | famille/admin | profil privé | État de workflow. |

## Champs interdits dans un document public

Le futur document public doit refuser au minimum :

- email, téléphone, WhatsApp et adresse ;
- coordonnées précises et lieux privés ;
- notes, historique détaillé et documents ;
- codes d'accès, mots de passe, PIN, jetons et secrets ;
- rôle, permissions ou identifiants d'authentification ;
- `createdBy`, `updatedBy` et autres UID internes ;
- configuration privée complète et métadonnées administratives.

## Constat sur l'UI actuelle

`Person.toPublicJson()` et les écrans masquent déjà plusieurs valeurs selon `PersonPrivacy`. Cette protection est seulement une projection client : le repository Firestore charge actuellement un `Person` complet depuis `members`, y compris en session publique. L'étape 3 devra faire consommer aux écrans publics un modèle/document physiquement public, avec compatibilité explicite pour les anciennes données.

## Décisions restant à valider

1. Les relations généalogiques doivent-elles toutes être publiques ou seulement accessibles à la famille ?
2. Le sexe, la photo, l'année de naissance et les informations de décès sont-ils publics par défaut ou seulement sur consentement ?
3. Qui représente techniquement le propriétaire d'une fiche et comment son UID est-il attribué ?
4. Les administrateurs peuvent-ils lire toutes les coordonnées privées ou seulement modérer les métadonnées ?
