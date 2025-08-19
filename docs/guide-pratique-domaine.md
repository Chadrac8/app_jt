# Guide Pratique : Connecter un Nom de Domaine

## 🎯 Objectif
Connecter votre nom de domaine personnalisé (ex: `monapp.com`) à votre application Flutter hébergée sur Firebase.

## 📋 Prérequis
- ✅ Nom de domaine acheté (chez OVH, Namecheap, GoDaddy, etc.)
- ✅ Application Flutter déployée sur Firebase
- ✅ Accès aux paramètres DNS de votre domaine
- ✅ Firebase CLI installé

## 🚀 Étapes Détaillées

### Étape 1 : Préparer l'Application

```bash
# 1. Construire l'application
cd "/Users/chadracntsouassouani/Downloads/perfect 12"
flutter build web --release

# 2. Déployer sur Firebase
firebase deploy --only hosting
```

### Étape 2 : Configurer le Domaine dans Firebase

#### Option A : Utiliser le script automatisé
```bash
./setup-domain.sh monapp.com
```

#### Option B : Configuration manuelle
1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet
3. Menu **Hosting** → **Domaines**
4. Cliquez **"Ajouter un domaine personnalisé"**
5. Entrez votre domaine : `monapp.com`
6. Choisissez **"Rediriger vers un domaine existant"** si vous voulez rediriger www vers le domaine principal

### Étape 3 : Configuration DNS

Firebase vous donnera des informations à configurer. Voici les configurations courantes :

#### Pour OVH
```
Type: A
Sous-domaine: (vide ou @)
Cible: 151.101.1.195
Cible: 151.101.65.195
```

#### Pour Cloudflare
```
Type: A
Name: @
IPv4: 151.101.1.195
IPv4: 151.101.65.195
Proxy status: DNS only (orange cloud désactivé)
```

#### Pour Namecheap
```
Type: A Record
Host: @
Value: 151.101.1.195
TTL: 3600
```

### Étape 4 : Configuration Sous-domaine WWW

```
Type: CNAME
Name: www
Value: monapp.com
TTL: 3600
```

### Étape 5 : Vérification

#### Vérifier la propagation DNS
```bash
# Vérifier les enregistrements A
nslookup monapp.com

# Vérifier les enregistrements CNAME
nslookup www.monapp.com

# Outil en ligne
open https://whatsmydns.net/#A/monapp.com
```

#### Tester l'accès
- ✅ http://monapp.com → redirige vers https://monapp.com
- ✅ https://monapp.com → fonctionne
- ✅ https://www.monapp.com → redirige vers https://monapp.com

## 📱 Exemples Concrets par Registrar

### OVH
1. Connectez-vous à votre [espace client OVH](https://www.ovh.com/manager/)
2. **Domaines** → Sélectionnez votre domaine → **Zone DNS**
3. Supprimez les anciens enregistrements A et AAAA
4. Ajoutez les nouveaux enregistrements A fournis par Firebase
5. Sauvegardez et attendez la propagation

### Cloudflare
1. Connectez-vous à [Cloudflare](https://dash.cloudflare.com)
2. Sélectionnez votre domaine → **DNS** → **Records**
3. Supprimez les anciens enregistrements A
4. Ajoutez les nouveaux enregistrements A
5. **Important** : Désactivez le proxy (cloud orange) pour les enregistrements Firebase

### GoDaddy
1. Connectez-vous à [GoDaddy](https://dcc.godaddy.com/)
2. **Mon compte** → **Domaines** → **Gérer DNS**
3. Dans les enregistrements A, modifiez ou ajoutez :
   - Type : A, Nom : @, Valeur : IP de Firebase
   - Type : CNAME, Nom : www, Valeur : votre-domaine.com

## ⚡ Scripts d'Automatisation

### Déploiement complet
```bash
# Déployer en production avec domaine
./deploy.sh prod
```

### Vérification post-déploiement
```bash
# Créer un script de vérification
cat > verify-domain.sh << 'EOF'
#!/bin/bash
DOMAIN=$1
echo "Vérification de $DOMAIN..."
curl -I https://$DOMAIN
curl -I https://www.$DOMAIN
echo "SSL Certificate:"
echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
EOF

chmod +x verify-domain.sh
./verify-domain.sh monapp.com
```

## 🔧 Configuration Avancée

### Optimisations Performance
```json
// Dans firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=604800"
          }
        ]
      }
    ]
  }
}
```

### Redirections personnalisées
```json
{
  "hosting": {
    "redirects": [
      {
        "source": "/ancien-chemin",
        "destination": "/nouveau-chemin",
        "type": 301
      }
    ]
  }
}
```

## 🚨 Troubleshooting

### Problème : "Site non accessible"
**Solutions :**
1. Vérifiez la propagation DNS (24-48h max)
2. Vérifiez les enregistrements DNS
3. Testez avec `nslookup`

### Problème : "Certificat SSL invalide"
**Solutions :**
1. Attendez la validation DNS complète
2. Vérifiez que le domaine pointe bien vers Firebase
3. Forcez le renouvellement dans Firebase Console

### Problème : "Erreur 404 sur certaines pages"
**Solutions :**
1. Vérifiez la configuration des rewrites dans `firebase.json`
2. Assurez-vous que toutes les routes pointent vers `/index.html`

## 📊 Monitoring

### Outils de surveillance
- **Google Analytics** : Trafic et comportement
- **Firebase Performance** : Métriques de performance
- **Search Console** : SEO et indexation
- **Uptime Robot** : Surveillance de disponibilité

### Métriques importantes
- Temps de chargement : < 3 secondes
- Disponibilité : > 99.9%
- Score Lighthouse : > 90
- Core Web Vitals : Vert

## 💡 Conseils Pro

1. **Sauvegardez** votre configuration DNS actuelle avant modification
2. **Testez** d'abord avec un sous-domaine (ex: test.monapp.com)
3. **Planifiez** les changements DNS en dehors des heures de pointe
4. **Documentez** votre configuration pour votre équipe
5. **Automatisez** le déploiement avec les scripts fournis

## 📞 Support

### Ressources utiles
- [Documentation Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Guide DNS Cloudflare](https://developers.cloudflare.com/dns/)
- [Support OVH](https://help.ovhcloud.com/)

### Commandes utiles
```bash
# Voir le statut Firebase
firebase projects:list
firebase hosting:sites:list

# Debug DNS
dig +trace monapp.com
whois monapp.com

# Test SSL
openssl s_client -connect monapp.com:443 -servername monapp.com
```
