# Guide de Configuration de Domaine pour votre Application

## Méthode 1 : Firebase Hosting (Recommandé)

### Prérequis
- Avoir un nom de domaine acheté (ex: mondomaine.com)
- Accès aux paramètres DNS de votre registrar de domaine
- Firebase CLI installé

### Étapes de Configuration

#### 1. Construire et déployer votre application
```bash
# Construire l'application pour le web
flutter build web --release

# Déployer sur Firebase Hosting
firebase deploy --only hosting
```

#### 2. Ajouter votre domaine personnalisé
```bash
# Connecter votre domaine à Firebase Hosting
firebase hosting:channel:deploy live --expires 30d
```

#### 3. Configuration dans la Console Firebase
1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet
3. Allez dans "Hosting" dans le menu de gauche
4. Cliquez sur "Ajouter un domaine personnalisé"
5. Entrez votre nom de domaine (ex: mondomaine.com)
6. Suivez les instructions pour la vérification

#### 4. Configuration DNS
Firebase vous donnera des enregistrements DNS à configurer :

**Pour un domaine racine (mondomaine.com) :**
- Type : A
- Nom : @ ou vide
- Valeur : Les adresses IP fournies par Firebase

**Pour un sous-domaine (www.mondomaine.com) :**
- Type : CNAME
- Nom : www
- Valeur : Le domaine fourni par Firebase (ex: mondomaine.web.app)

#### 5. Redirection automatique
Firebase configurera automatiquement :
- Redirection HTTP vers HTTPS
- Certificat SSL gratuit
- CDN global

### Commandes utiles
```bash
# Voir le statut du déploiement
firebase hosting:channel:list

# Voir les domaines configurés
firebase hosting:channel:open live

# Redéployer
firebase deploy --only hosting
```

## Méthode 2 : Hébergement Web Standard

### Si vous n'utilisez pas Firebase Hosting

#### 1. Construire l'application
```bash
flutter build web --release
```

#### 2. Télécharger les fichiers
- Le dossier `build/web` contient tous les fichiers nécessaires
- Téléchargez ce contenu sur votre serveur web

#### 3. Configuration du serveur
Configurez votre serveur web pour :
- Servir le fichier `index.html` pour toutes les routes
- Activer HTTPS
- Configurer les en-têtes CORS si nécessaire

#### 4. Configuration DNS
- Type : A
- Nom : @ (pour le domaine racine)
- Valeur : Adresse IP de votre serveur

## Méthode 3 : Services d'Hébergement Populaires

### Netlify
1. Connectez votre repository GitHub
2. Configurez la commande de build : `flutter build web`
3. Dossier de publication : `build/web`
4. Ajoutez votre domaine dans les paramètres

### Vercel
1. Importez votre projet
2. Configurez Flutter dans les paramètres
3. Ajoutez votre domaine personnalisé

### GitHub Pages
1. Activez GitHub Pages dans les paramètres du repository
2. Configurez pour utiliser la branche `gh-pages`
3. Utilisez GitHub Actions pour automatiser le déploiement

## Configuration DNS Générale

### Chez votre registrar de domaine :

**Domaine principal (mondomaine.com) :**
```
Type: A
Nom: @
Valeur: [IP de votre hébergeur]
TTL: 3600
```

**Sous-domaine www :**
```
Type: CNAME
Nom: www
Valeur: mondomaine.com
TTL: 3600
```

**Sous-domaine pour l'application :**
```
Type: CNAME
Nom: app
Valeur: [domaine de votre hébergeur]
TTL: 3600
```

## Certificat SSL

### Avec Firebase Hosting
- Certificat SSL automatique et gratuit
- Renouvellement automatique

### Avec d'autres hébergeurs
- Let's Encrypt (gratuit)
- Cloudflare (gratuit avec CDN)
- Certificat payant de votre hébergeur

## Vérification et Tests

### 1. Vérifier la propagation DNS
```bash
# Vérifier les enregistrements DNS
nslookup mondomaine.com
dig mondomaine.com

# Tester depuis différents endroits
# Utilisez des outils en ligne comme whatsmydns.net
```

### 2. Tester l'application
- Vérifiez que toutes les routes fonctionnent
- Testez la redirection HTTPS
- Vérifiez les performances
- Testez sur différents appareils

### 3. Outils de diagnostic
- Google PageSpeed Insights
- GTmetrix
- WebPageTest
- Lighthouse (intégré dans Chrome DevTools)

## Délais de Propagation

- **DNS** : 24-48 heures maximum
- **Certificat SSL** : 1-2 heures avec Firebase
- **CDN** : Quelques minutes à quelques heures

## Dépannage Courant

### Problème : Site inaccessible
- Vérifiez la propagation DNS
- Contrôlez les enregistrements DNS
- Vérifiez que les fichiers sont bien uploadés

### Problème : Certificat SSL invalide
- Attendez la propagation DNS complète
- Vérifiez la configuration du domaine
- Contactez le support de votre hébergeur

### Problème : Routes ne fonctionnent pas
- Configurez la réécriture d'URL
- Ajoutez un fichier `.htaccess` si nécessaire
- Vérifiez la configuration du serveur

## Conseils de Performance

1. **Activez la compression GZIP**
2. **Configurez la mise en cache**
3. **Utilisez un CDN**
4. **Optimisez les images**
5. **Minifiez les ressources CSS/JS**

## Sécurité

1. **Forcez HTTPS**
2. **Configurez les en-têtes de sécurité**
3. **Limitez les domaines autorisés pour CORS**
4. **Activez la protection DDoS si disponible**
