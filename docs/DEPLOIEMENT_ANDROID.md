# 🚀 Déploiement Android — Google Play (Yobante Colis)

> **En une phrase :** vous écrivez les nouveautés, vous poussez sur `release`,
> la chaîne vérifie tout, vous approuvez d'un clic, et l'app arrive chez vos
> testeurs en **Tests fermés - Alpha** — sans ouvrir Play Console.

- Identifiant de l'app (définitif) : **`com.yobante.colis`**
- API de production : `https://api.yobanterek.com` (valeur par défaut de `lib/core/config/env.dart`)
- Chaîne identique à celle de Widjila (`suivie_chantier/mobile`).

---

## 🔧 Mise en place (une seule fois, dans cet ordre)

Les commandes ci-dessous sont pour **PowerShell**, lancées depuis le dossier
`yobante-colis-mobile`.

### 1️⃣ Firebase : déclarer le nouvel identifiant

L'ancien identifiant `com.yobnate.yobnate_colis` est abandonné : son
`google-services.json` ne fonctionne plus.

✅ **Fait** — projet Firebase **`yobante-colis`**, applications Android et iOS
`com.yobante.colis` :

- `android/app/google-services.json` (Android) ;
- `ios/Runner/GoogleService-Info.plist` (iOS, référencé dans le projet Xcode
  pour être embarqué dans l'app).

Ces deux fichiers ne sont **jamais committés** (`.gitignore`) : gardez-en une
copie de sauvegarde. Sur un autre poste, re-téléchargez-les depuis la console
Firebase › ⚙️ **Paramètres du projet** › **Vos applications**.

L'ancien fichier `com.yobnate` (projet `sign-8b019`) a été supprimé.

### 2️⃣ Créer la clé de signature (keystore)

> ⚠️ **Le fichier `.jks` et ses mots de passe sont irremplaçables.** Sauvegardez
> les deux hors de l'ordinateur (gestionnaire de mots de passe + copie du
> fichier). Ne les committez jamais.

```powershell
keytool -genkey -v -keystore android\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Puis créer **`android/key.properties`** (exclu de git) :

```properties
storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` est **relatif au dossier `android/`**. Sans ce fichier, un build
`--release` échoue volontairement (voir `android/app/build.gradle.kts`).

### 3️⃣ Premier AAB, construit et envoyé à la main

Google Play n'accepte les envois automatiques que pour une app qui existe déjà
et a reçu un premier fichier depuis Play Console.

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

Fichier produit : `build\app\outputs\bundle\release\app-release.aab`.

1. **Play Console** › **Créer une application** · nom `Yobante Colis` · langue
   par défaut Français · Application · Gratuite.
2. **Tester et publier** › **Tests fermés** › **Alpha** › **Créer une
   version** › accepter la **signature d'application par Google Play** ›
   déposer `app-release.aab` › notes de version › **Enregistrer et publier**.
3. Remplir les rubriques obligatoires du **Tableau de bord** (règles de
   confidentialité, sécurité des données — voir
   `docs/PLAY_STORE_DATA_SAFETY.md`, classification du contenu, public cible,
   fiche Play Store avec captures d'écran).

> **Compte développeur personnel créé après novembre 2023 :** Google exige
> **12 testeurs** inscrits aux Tests fermés pendant **14 jours d'affilée**
> avant de pouvoir demander l'accès à la production. Invitez-les dès
> maintenant (Tests fermés › Alpha › Testeurs).

### 4️⃣ Compte de service Google Play (accès de l'automatisation)

1. **Google Cloud Console** › créer un projet (ex. `yobante-deploy`) › **API
   et services** › activer **Google Play Android Developer API**.
2. **IAM et administration** › **Comptes de service** › **Créer** (ex.
   `fastlane-deploy`) › onglet **Clés** › **Ajouter une clé** › JSON →
   fichier téléchargé.
3. **Play Console** › **Utilisateurs et autorisations** › **Inviter un
   utilisateur** › l'adresse e-mail du compte de service › autorisations
   **pour l'app Yobante Colis uniquement** : afficher les informations de
   l'app, publier sur les canaux de test, gérer les versions de test.

Les droits peuvent mettre **24 à 36 h** à devenir actifs.

### 5️⃣ Empreinte de la clé d'importation

**Play Console** › Yobante Colis › **Tester et publier** › **Intégrité de
l'application** › **Signature de l'application** › section **« Certificat de
la clé d'importation »** › copier l'empreinte **SHA-256** (`AB:CD:…`).

Vérification locale (elle doit être identique) :

```powershell
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

### 6️⃣ Secrets et variable GitHub

Encoder les fichiers en base64 (fichiers `*.b64.txt` exclus de git, à
supprimer après usage) :

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\upload-keystore.jks")) | Set-Content -NoNewline keystore.b64.txt
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Content -NoNewline google-services.b64.txt
```

**GitHub** › `jeune-dev/yobante-colis-mobile` › **Settings** › **Secrets and
variables** › **Actions** :

| Onglet | Nom | Valeur |
|---|---|---|
| Secrets | `ANDROID_KEYSTORE_BASE64` | contenu de `keystore.b64.txt` |
| Secrets | `ANDROID_KEYSTORE_PROPERTIES` | contenu de `android/key.properties` (la ligne `storeFile` est remplacée automatiquement) |
| Secrets | `GOOGLE_SERVICES_JSON_BASE64` | contenu de `google-services.b64.txt` |
| Secrets | `PLAY_SERVICE_ACCOUNT_JSON` | contenu **brut** du JSON du compte de service (étape 4) |
| Variables | `ANDROID_UPLOAD_CERT_SHA256` | empreinte copiée à l'étape 5 |

```powershell
Remove-Item keystore.b64.txt, google-services.b64.txt
```

### 7️⃣ Environnement d'approbation `google-play`

> ⚠️ **Indispensable.** Sans cette étape, GitHub crée l'environnement tout
> seul, **sans approbation** : la publication partirait sans votre clic.

1. **Settings** › **Environments** › **New environment** › nom
   **`google-play`** (exactement).
2. Cocher **Required reviewers** › ajouter **votre compte**.
3. **Deployment branches and tags** › **Selected branches and tags** ›
   ajouter `release` **et** `main`.
4. **Save protection rules**.

### 8️⃣ Protection de la branche `release`

**Settings** › **Rules** › **Rulesets** › **New branch ruleset** › nom
`release protégée` · **Active** · cible `release` · cocher **Restrict
deletions** et **Block force pushes** › **Create**.

### 9️⃣ Essai à blanc

**Actions** › **Android — Google Play** › **Run workflow** (case cochée). Toute
la chaîne s'exécute et Google Play **valide** l'envoi, mais rien n'est publié.

---

## ⚡ Publier une nouvelle version (au quotidien)

| | Étape | Où |
|:---:|---|---|
| 1 | Écrire les nouveautés dans **`fastlane/notes/fr-FR.txt`** (500 caractères max, **différentes** du déploiement précédent) | éditeur |
| 2 | *Seulement pour une nouvelle version visible :* changer `version:` dans `pubspec.yaml` (ex. `1.0.0` → `1.0.1`) | éditeur |
| 3 | Committer et pousser sur `main`, puis lancer la publication | terminal |
| 4 | Vérifier le résumé du déploiement, cliquer **Review deployments › Approve** | GitHub |

```bash
git push origin main
git push origin main:release
```

- Un push sur `main` seul ne publie **rien**. Seul `main:release` déclenche.
- Le **numéro de build** est automatique : dernier numéro connu de Google
  Play + 1. Le chiffre après le `+` dans `pubspec.yaml` est ignoré.

## 🛤️ La chaîne

```
 1 · Contrôles d'entrée (commit sur main, notes, version)
        ├── 2a · Analyse du code (flutter analyze)
        ├── 2b · Tests & couverture
        └── 2c · Sécurité (Gitleaks + OSV-Scanner)
 3 · Compilation & contrôle de l'AAB (signature, identité, targetSdk, permissions, taille, API, Firebase)
 4 · Test de démarrage sur émulateur Android 14
 5 · ✋ VOTRE APPROBATION
 6 · Publication en Tests fermés - Alpha + vérification + tag/Release GitHub
 7 · Bilan
```

Au premier ❌, **rien n'est publié**.

> Le test de démarrage joint une capture d'écran : elle sera **noire**, c'est
> normal — `MainActivity` interdit les captures (`FLAG_SECURE`).

## 🛠️ Dépannage

| Message | Cause | Solution |
|---|---|---|
| `Seul du code présent sur main peut être publié` | `release` poussé depuis une autre branche | `git push origin main` puis `git push origin main:release` |
| `Les notes n'ont pas changé depuis …` | notes identiques au déploiement précédent | modifier `fastlane/notes/fr-FR.txt` |
| `Secret GitHub manquant : …` | configuration incomplète | étape 6 ci-dessus |
| `The caller does not have permission` / `Package not found` | droits du compte de service pas encore actifs, ou premier AAB jamais envoyé à la main | attendre 24-36 h · faire l'étape 3 |
| Signature ❌ « empreinte ≠ attendue » | mauvais keystore ou variable erronée | vérifier `ANDROID_KEYSTORE_BASE64` et `ANDROID_UPLOAD_CERT_SHA256` |
| `Keystore was tampered with, or password was incorrect` | mot de passe erroné | corriger `ANDROID_KEYSTORE_PROPERTIES` |
| `Signature release introuvable : créez android/key.properties` (en local) | pas de `key.properties` | étape 2 |
| `No matching client found for package name` | `google-services.json` d'un autre identifiant | étape 1 |
| `pubspec.yaml annonce … plus ancienne que …` | version visible inférieure à celle en ligne | augmenter `version:` |

## 🗂️ Fichiers

| Fichier | Rôle |
|---|---|
| `.github/workflows/android-release.yml` | la chaîne de publication |
| `android/fastlane/Fastfile` | Google Play : numéro de build, compilation, envoi, vérification |
| `android/fastlane/Appfile` | package et clé du compte de service |
| `Gemfile` | version de fastlane |
| `fastlane/notes/fr-FR.txt` | **vos notes de version** |
| `tool/ci/controle_aab.py` | contrôle de l'AAB |
| `tool/ci/android_reference.json` | valeurs de référence (package, API, permissions acceptées) |
| `tool/ci/test_demarrage.sh` | test de démarrage sur émulateur |
| `.gitleaks.toml` | règles de la recherche de secrets |
| `.github/SECRETS.md` | liste des secrets |
