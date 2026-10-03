# Secrets et variables GitHub Actions

À configurer dans **Settings → Secrets and variables → Actions** du dépôt.
Procédure complète (comment produire chaque valeur) : `docs/DEPLOIEMENT_ANDROID.md`.

## Secrets (onglet *Secrets*)

| Nom | Utilisé par | Contenu |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | android-release.yml | Keystore de signature (`upload-keystore.jks`) encodé en base64 |
| `ANDROID_KEYSTORE_PROPERTIES` | android-release.yml | Contenu de `android/key.properties` (mots de passe + alias) |
| `GOOGLE_SERVICES_JSON_BASE64` | android-release.yml, ci.yml | `google-services.json` Firebase (package `com.yobante.colis`) encodé en base64 |
| `PLAY_SERVICE_ACCOUNT_JSON` | android-release.yml | Clé JSON du compte de service Google Play (contenu brut) |
| `API_BASE_URL` | ci.yml (facultatif) | URL de l'API ; à défaut l'app vise `https://api.yobanterek.com` |

## Variable (onglet *Variables*)

| Nom | Contenu |
|---|---|
| `ANDROID_UPLOAD_CERT_SHA256` | Empreinte SHA-256 du certificat de la clé d'importation (Play Console) |

> Ne jamais committer ces valeurs dans le code source.
