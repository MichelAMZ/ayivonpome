# Contrôle local des secrets

Depuis la racine du projet :

```text
dart run tooling/security/check_secrets.dart
```

Après un build Web :

```text
dart run tooling/security/check_secrets.dart --include-build
```

Le contrôle inspecte les sources et assets textuels, refuse les listes de codes non vides, les valeurs sensibles JSON, plusieurs formes historiques et les littéraux associés à des secrets. Toute valeur signalée est masquée.

Les exclusions sont limitées aux dépendances, à `.git`, `.dart_tool`, aux formats binaires et au code du scanner lui-même. `build/web` n'est inclus qu'avec `--include-build`.
