# Firebase Emulator Suite sous Windows

## Prérequis vérifiés

- OpenJDK 17.0.18 (`JAVA_HOME` vers Eclipse Adoptium) ;
- Firebase CLI autonome avec cache émulateur local ;
- Node.js et npm disponibles ;
- ports : Firestore `8080`, Auth `9099`, UI `4000` ;
- projet local explicite : `demo-ayivon-preprod`.

La configuration `.firebaserc` utilise le projet factice par défaut. Le projet
réel n'existe que sous l'alias `production`. Ne jamais ajouter `--project
production` à une commande de test.

## Installation

```powershell
cd firebase_tests
npm install
cd ..
```

## Commande reproductible

Sous cette installation Windows, le binaire Firebase autonome injecte
`PKG_EXECPATH=firebase.exe`. Un script enfant `npm test` lancé par
`emulators:exec` échoue alors avec une erreur `stdin`. Appeler directement Node
et Mocha :

```powershell
firebase emulators:exec `
  --project demo-ayivon-preprod `
  --only firestore,auth `
  "node firebase_tests/node_modules/mocha/bin/mocha.js --timeout 20000 firebase_tests/test/**/*.test.cjs"
```

Cette commande démarre les émulateurs, exécute les tests et les arrête même en
cas d'échec. Aucun `firebase login` n'est requis par les règles elles-mêmes ; la
CLI peut néanmoins afficher l'utilisateur déjà connecté lors de son démarrage.

## Diagnostic Windows

Le code Windows `CreateProcessAsUserW 1312` indique ici une session du lanceur
isolé devenue indisponible. Il ne provient ni des règles ni de Java. Relancer la
commande dans une session PowerShell normale résout le lancement.

Contrôles utiles :

```powershell
node --version
npm --version
firebase --version
java -version
$env:JAVA_HOME
Get-NetTCPConnection -State Listen -LocalPort 4000,8080,9099
Get-Process java,node -ErrorAction SilentlyContinue
```

Consulter `firestore-debug.log` si les règles ne compilent pas. Vérifier aussi
les ports, le PATH, l'ExecutionPolicy et le cache dans
`%USERPROFILE%\.cache\firebase\emulators`. Ne jamais substituer un compte de
service de production.
