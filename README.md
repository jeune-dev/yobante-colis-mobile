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

# Lancer en développement, sur le backend local (npm run dev sur le Mac)
flutter run --dart-define-from-file=dart_defines.local.json

# Lancer en développement sur la production
flutter run --dart-define-from-file=dart_defines.json

# Build release Android (production)
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Sans `--dart-define-from-file`, `flutter run` vise le backend local et
`flutter build` la production (voir `lib/core/config/env.dart`).

## Variables d'environnement

| Fichier | API | Usage |
|---|---|---|
| `dart_defines.json` | `https://api.yobanterek.com` | builds publiés, tests sur la production |
| `dart_defines.local.json` (non versionné) | `http://<IP du Mac>:3000` | développement sur le backend local |

`dart_defines.local.json` contient l'adresse du Mac sur le Wi-Fi (`ipconfig getifaddr en0`),
joignable par l'iPhone, le simulateur et l'émulateur :

```json
{
  "API_BASE_URL": "http://192.168.1.11:3000"
}
```

## Tests

```bash
flutter test
```
