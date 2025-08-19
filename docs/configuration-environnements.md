# Configuration des environnements pour le déploiement

## Environnements disponibles

### Development (dev)
- **URL**: https://perfect-12--dev.web.app
- **Durée**: 7 jours
- **Base de données**: Firestore (mode test)
- **Authentification**: Firebase Auth (mode test)

### Staging (staging)  
- **URL**: https://perfect-12--staging.web.app
- **Durée**: 30 jours
- **Base de données**: Firestore (données de test)
- **Authentification**: Firebase Auth (comptes de test)

### Production (prod)
- **URL**: https://perfect-12.web.app + votre domaine personnalisé
- **Durée**: Permanent
- **Base de données**: Firestore (données réelles)
- **Authentification**: Firebase Auth (comptes réels)

## Variables d'environnement

Les variables sont configurées via --dart-define lors du build :

```dart
// Dans votre code Dart
const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

// Utilisation
if (environment == 'production') {
  // Configuration production
} else if (environment == 'staging') {
  // Configuration staging  
} else {
  // Configuration développement
}
```

## Configuration Firebase par environnement

### firebase.json
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(eot|otf|ttf|ttc|woff|font.css)",
        "headers": [
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=604800"
          }
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
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

## Domaines personnalisés

### Configuration DNS requise

#### Domaine principal (mondomaine.com)
```
Type: A
Name: @
Value: [IP fournie par Firebase]
TTL: 3600
```

#### Sous-domaine www
```
Type: CNAME  
Name: www
Value: mondomaine.com
TTL: 3600
```

#### Sous-domaine app (optionnel)
```
Type: CNAME
Name: app  
Value: perfect-12.web.app
TTL: 3600
```

### Commandes Firebase pour les domaines

```bash
# Lister les domaines configurés
firebase hosting:sites:list

# Ajouter un domaine personnalisé
firebase hosting:sites:create votre-site-id

# Voir les canaux de déploiement
firebase hosting:channel:list
```

## Scripts de déploiement

### Déploiement rapide
```bash
# Développement
./deploy.sh dev

# Staging  
./deploy.sh staging

# Production
./deploy.sh prod
```

### Déploiement manuel
```bash
# 1. Nettoyer
flutter clean && flutter pub get

# 2. Construire
flutter build web --release --dart-define=ENVIRONMENT=production

# 3. Déployer
firebase deploy --only hosting
```

## Monitoring et Analytics

### URLs de monitoring
- **Firebase Console**: https://console.firebase.google.com
- **Google Analytics**: https://analytics.google.com  
- **Search Console**: https://search.google.com/search-console

### Métriques importantes
- Temps de chargement
- Taux de conversion
- Erreurs JavaScript
- Utilisation mobile vs desktop
- Géolocalisation des utilisateurs

## Sécurité

### Headers de sécurité recommandés
```json
{
  "headers": [
    {
      "source": "**",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options", 
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains"
        }
      ]
    }
  ]
}
```

### Règles de sécurité Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Production rules
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Problèmes courants

#### Erreur 404 sur les routes
**Solution**: Vérifier la configuration des rewrites dans firebase.json

#### Certificat SSL non valide  
**Solution**: Attendre 24-48h pour la propagation DNS

#### Erreurs CORS
**Solution**: Configurer les headers CORS dans firebase.json

#### Build échoue
**Solution**: 
```bash
flutter clean
flutter pub get
flutter pub deps
```

### Logs et debugging
```bash
# Logs Firebase
firebase functions:log

# Logs de déploiement
firebase hosting:channel:list --json

# Debug local
flutter run -d web-server --web-port=8080
```
