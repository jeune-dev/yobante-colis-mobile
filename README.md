# Yobante Colis — Application Mobile

Application Flutter de gestion de colis et livraisons pour la plateforme Yobante.

## Stack technique

- **Flutter** 3.x / Dart 3.x
- **Architecture** : Clean Architecture (data / domain / presentation) par feature
- **State management** : flutter_bloc ^9.1.1
- **Injection de dépendances** : get_it ^9.2.1
- **HTTP** : Dio ^5.x avec intercepteurs (auth, retry, refresh token)
- **Stockage sécurisé** : flutter_secure_storage (JWT + refresh token)
- **Firebase** : Crashlytics + FCM (push notifications)
- **Monades** : dartz (Either pour la gestion d'erreurs)

## Structure du projet

```
lib/
├── core/
│   ├── config/        # Env, UserRole
│   ├── constants/     # AppConstants
│   ├── error/         # Failures, exceptions
│   ├── routes/        # AppRouter
│   ├── services/      # TokenService, FcmService, AuthEventBus
│   ├── theme/         # AppColor, AppTextStyle
│   └── widgets/       # Widgets partagés
└── features/
    ├── auth/          # Authentification (login, register)
    ├── colis/         # Gestion des colis
    ├── account/       # Profil utilisateur
    ├── notifications/ # Notifications push
    ├── villes/        # Référentiel villes
    ├── admin/         # Tableau de bord administrateur
    └── paiements/     # Factures et paiements
```

## Lancer le projet

```bash
# Installer les dépendances
flutter pub get

# Lancer en développement
flutter run --dart-define-from-file=dart_defines.json

# Build release Android
flutter build apk --release --dart-define-from-file=dart_defines.json
```

## Adresse de l'API

Pas de fichier `.env` : dans une app mobile, l'adresse de l'API est **compilée
dans l'application** (`lib/core/config/env.dart`).

- Par défaut (production) : `https://api.yobanterek.com` + préfixe `/api/v1`
  → toutes les requêtes partent vers **`https://api.yobanterek.com/api/v1`**.
- Pour viser un autre serveur (backend local, par exemple), passer
  **l'origine seule, sans `/api/v1`** (le préfixe est ajouté automatiquement) :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`dart_defines.json` contient la valeur de production, pour
`--dart-define-from-file=dart_defines.json`.

## Tests

```bash
flutter test
```
