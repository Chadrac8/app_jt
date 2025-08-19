# 🚀 Configuration Rapide de votre Domaine

## Votre Configuration Actuelle
- **Projet Firebase** : ProjetActuel (hjye25u8iwm0i0zls78urffsc0jcgj)
- **URL par défaut** : https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app
- **Status** : ✅ Hosting configuré et actif

## 📋 Étapes pour Connecter votre Domaine

### 1. Utiliser le Script Automatisé (Recommandé)
```bash
# Remplacez "mondomaine.com" par votre domaine réel
./setup-domain.sh mondomaine.com
```

### 2. Configuration Manuelle

#### A. Déployer votre application
```bash
# Construction et déploiement
flutter build web --release
firebase deploy --only hosting --project hjye25u8iwm0i0zls78urffsc0jcgj
```

#### B. Ajouter le domaine dans Firebase
1. Allez sur : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/hosting/main
2. Cliquez sur **"Ajouter un domaine personnalisé"**
3. Entrez votre domaine (ex: `mondomaine.com`)
4. Suivez les instructions de vérification

#### C. Configurer les DNS
Firebase vous donnera des enregistrements à configurer :

**Domaine principal (mondomaine.com) :**
```
Type: A
Nom: @ ou (vide)
Valeur: [IPs fournies par Firebase]
TTL: 3600
```

**Sous-domaine www :**
```
Type: CNAME
Nom: www
Valeur: mondomaine.com
TTL: 3600
```

## 🔧 Scripts Disponibles

### Déploiement par environnement
```bash
# Développement (7 jours)
./deploy.sh dev

# Staging (30 jours) 
./deploy.sh staging

# Production (permanent)
./deploy.sh prod
```

### Configuration de domaine
```bash
# Configuration automatisée
./setup-domain.sh votredomaine.com

# Vérification
./verify-domain.sh votredomaine.com
```

## 📱 Exemples par Registrar

### OVH
1. Manager OVH → Domaines → Zone DNS
2. Supprimer anciens enregistrements A/AAAA
3. Ajouter nouveaux enregistrements A de Firebase

### Cloudflare  
1. Dashboard → DNS Records
2. Ajouter enregistrements A
3. **Important** : Désactiver le proxy (cloud orange)

### Namecheap/GoDaddy
1. DNS Management
2. Modifier enregistrements A existants
3. TTL recommandé : 3600 secondes

## ⚡ URLs Rapides

- **Console Firebase** : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj
- **Hosting Dashboard** : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/hosting/main
- **Votre App Actuelle** : https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app

## ✅ Checklist Post-Configuration

- [ ] Application déployée avec succès
- [ ] Domaine ajouté dans Firebase Console
- [ ] Enregistrements DNS configurés
- [ ] Propagation DNS vérifiée (24-48h max)
- [ ] HTTPS fonctionne automatiquement
- [ ] Redirection www → domaine principal
- [ ] Test sur mobile et desktop

## 🆘 Dépannage Rapide

### Site inaccessible
```bash
# Vérifier DNS
nslookup votredomaine.com
dig votredomaine.com

# Vérifier propagation
open https://whatsmydns.net/#A/votredomaine.com
```

### Erreur SSL
- Attendre 24-48h pour validation DNS
- Vérifier que DNS pointe vers Firebase
- Forcer renouvellement dans Console Firebase

### Routes 404
- Vérifier `firebase.json` rewrites
- Redéployer si nécessaire

## 💡 Prochaines Étapes

1. **Monitoring** : Configurer Google Analytics
2. **Performance** : Optimiser avec Lighthouse  
3. **SEO** : Ajouter à Search Console
4. **Sécurité** : Configurer CSP headers
5. **Backup** : Automatiser les sauvegardes

## 📞 Support

Si vous avez des questions :
1. Consultez la documentation dans `/docs/`
2. Vérifiez les logs Firebase
3. Testez avec les scripts fournis
4. Contactez le support Firebase si nécessaire

---
**Temps estimé** : 30 minutes à 2 heures (selon la propagation DNS)
**Coût** : Gratuit avec Firebase (jusqu'à certaines limites)
**SSL** : Automatique et gratuit
