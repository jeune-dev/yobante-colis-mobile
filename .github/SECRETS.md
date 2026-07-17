# Secrets GitHub Actions requis

À configurer dans **Settings → Secrets and variables → Actions** du dépôt :

| Nom du secret | Description |
|---|---|
| `GOOGLE_SERVICES_JSON` | Contenu du fichier `google-services.json` Firebase (Android) |
| `API_BASE_URL` | URL de l'API backend en production (ex: `https://api.yobante.com`) |

> Ne jamais committer ces valeurs dans le code source.
