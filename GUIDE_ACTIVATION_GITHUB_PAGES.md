# 🌐 GUIDE D'ACTIVATION GITHUB PAGES

## 🎯 Objectif

Rendre votre page de privacy policy accessible à l'URL :
`https://chadrac8.github.io/app_jt/privacy_policy.html`

## ✅ Étapes à suivre

### 1. Activer GitHub Pages sur votre repository

1. **Aller sur votre repository GitHub :**
   - Naviguer vers : `https://github.com/Chadrac8/app_jt`

2. **Accéder aux paramètres :**
   - Cliquer sur l'onglet **"Settings"** (en haut à droite)

3. **Configurer GitHub Pages :**
   - Dans le menu de gauche, cliquer sur **"Pages"**
   - Dans la section **"Source"** :
     - Sélectionner **"Deploy from a branch"**
     - Choisir la branche **"main"**
     - Laisser le dossier sur **"/ (root)"**
   - Cliquer sur **"Save"**

### 2. Vérification

Après quelques minutes, votre page sera accessible à :
```
https://chadrac8.github.io/app_jt/privacy_policy.html
```

GitHub vous donnera aussi une URL de base :
```
https://chadrac8.github.io/app_jt/
```

### 3. Test de fonctionnement

Une fois GitHub Pages activé, testez les URLs :

✅ **Page principale :** `https://chadrac8.github.io/app_jt/`  
✅ **Privacy Policy :** `https://chadrac8.github.io/app_jt/privacy_policy.html`

## 📄 Contenu de votre Privacy Policy

Votre fichier `privacy_policy.html` contient déjà :

✅ **Design professionnel** avec CSS intégré  
✅ **Contenu RGPD compliant**  
✅ **Informations spécifiques** à Jubilé Tabernacle  
✅ **Contact** et droits des utilisateurs  
✅ **Responsive design** pour mobile/desktop  

## 🔄 Mises à jour futures

Pour modifier la privacy policy :

1. **Éditer le fichier :**
   ```bash
   # Modifier privacy_policy.html localement
   git add privacy_policy.html
   git commit -m "📝 Mise à jour privacy policy"
   git push origin main
   ```

2. **Délai de mise à jour :**
   - GitHub Pages se met à jour automatiquement
   - Délai : 1-10 minutes après le push

## 🎨 Personnalisation possible

Si vous voulez personnaliser la page :

### Couleurs de votre église
```css
h1 { color: #860505; } /* Rouge de votre logo */
```

### Logo/Image
Ajoutez votre logo en créant un dossier `assets/` :
```html
<img src="assets/logo-jubile-tabernacle.png" alt="Logo" width="100">
```

### Informations de contact
Modifiez dans le HTML :
```html
<li>📧 <strong>Email :</strong> privacy@jubile-tabernacle.fr</li>
```

## 🔗 Utilisation dans l'application

Une fois GitHub Pages activé, mettez à jour les références dans votre app si nécessaire :

### Play Store
Le fichier `build_play_store.sh` référence déjà :
```bash
https://chadrac8.github.io/app_jt/privacy_policy.html
```

### Configuration app
Dans `lib/config/privacy_policy_config.dart`, vous pouvez garder :
```dart
static const String privacyPolicyUrl = "https://jubile-tabernacle.fr/privacy-policy";
```
Ou pointer vers GitHub :
```dart
static const String privacyPolicyUrl = "https://chadrac8.github.io/app_jt/privacy_policy.html";
```

## 📱 Avantages GitHub Pages

✅ **Gratuit** : Hébergement GitHub gratuit  
✅ **Rapide** : CDN mondial de GitHub  
✅ **Fiable** : 99.9% uptime  
✅ **HTTPS** : Sécurisé par défaut  
✅ **Version control** : Historique des modifications  

## 🚨 Points d'attention

### Délai d'activation
- Première activation : 10-20 minutes
- Mises à jour : 1-10 minutes

### Cache
- Votre navigateur peut mettre en cache
- Utilisez Ctrl+F5 pour forcer le rafraîchissement

### URL sensible à la casse
- `privacy_policy.html` (avec underscore)
- Pas `privacy-policy.html` (avec tiret)

## ✅ Checklist finale

- [ ] Repository GitHub Pages activé
- [ ] URL `https://chadrac8.github.io/app_jt/privacy_policy.html` accessible
- [ ] Page s'affiche correctement sur mobile
- [ ] Liens de contact fonctionnels
- [ ] Date de dernière mise à jour actuelle
- [ ] Google Play Store référence l'URL GitHub
- [ ] App mobile peut ouvrir la page