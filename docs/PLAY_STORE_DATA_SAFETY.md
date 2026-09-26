# Data Safety — Google Play Store
## Application SIGN | com.signapp.sign_application

> Ce document est à remplir dans la console Google Play :
> Console → Votre app → Politique de confidentialité & Data safety → Data safety

---

## 1. Collecte et partage de données

### L'app collecte-t-elle des données utilisateur ?
**OUI**

### L'app partage-t-elle des données avec des tiers ?
**OUI** — Firebase Crashlytics (diagnostics de crash uniquement, anonymisés)

---

## 2. Types de données collectées

| Catégorie | Données | Collecté ? | Partagé ? | Finalité |
|---|---|---|---|---|
| **Informations personnelles** | Nom, prénom | Oui | Non | Fonctionnalité de l'app |
| **Informations personnelles** | Adresse email | Oui | Non | Authentification |
| **Informations personnelles** | Numéro de téléphone | Oui | Non | Profil utilisateur |
| **Informations personnelles** | Numéro CNI / document | Oui | Non | Création de contrats |
| **Informations personnelles** | Adresse postale | Oui | Non | Contrats immobiliers |
| **Finances** | Données salariales | Oui | Non | Fiches de paie |
| **Photos et vidéos** | Photo de profil | Oui | Non | Profil utilisateur |
| **Photos et vidéos** | Image de signature | Oui | Non | Signature électronique |
| **Fichiers et documents** | Contrats PDF | Oui | Non | Téléchargement documents |
| **Identifiants d'app** | Token JWT (sécurisé) | Oui | Non | Authentification session |
| **Diagnostics** | Logs de crash | Oui | Oui (Firebase) | Stabilité app |

---

## 3. Pratiques de sécurité

| Pratique | Statut |
|---|---|
| Les données sont chiffrées en transit | Oui (HTTPS/TLS uniquement) |
| Les données peuvent être supprimées sur demande | Oui (suppression de compte) |
| L'app respecte la politique famille Google Play | Oui |
| L'app collecte des données d'enfants (<13 ans) | Non |

---

## 4. Actions requises dans la console Play

1. **Politique de confidentialité** :
   - Héberger le texte (actuellement in-app) sur une URL publique
   - Exemple : https://sign-app.sn/politique-confidentialite
   - OU créer une page GitHub Pages gratuite

2. **Data Safety form** :
   - Remplir le formulaire dans : Console → App content → Data safety
   - Déclarer chaque type de données selon le tableau ci-dessus

3. **App access** :
   - L'app nécessite un compte : **OUI**
   - Fournir un compte de test à Google (email + mot de passe)
   - Section : Console → App content → App access

4. **Ads** :
   - L'app contient des publicités : **NON**

---

## 5. Compte de test pour les reviewers Google

> Attention : Google exige un compte fonctionnel pour reviewer l'app.
> Créer un compte de démonstration AVANT la soumission :

```
Email    : demo@sign-app.sn
Password : Demo2026!
Rôle     : Professionnel (accès complet)
```

---

## 6. Contacts légaux

- **Développeur** : [Ton nom / entreprise]
- **Email** : ballabeye.dev04@gmail.com
- **Site web** : [URL de ton site]
- **Adresse** : Sénégal
