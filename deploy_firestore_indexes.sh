#!/bin/bash

# Script pour déployer les index Firestore manquants
# Corrige les erreurs d'index pour les rôles et permissions

echo "🔥 Déploiement des index Firestore..."

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé. Installez-le avec:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "firestore.indexes.json" ]; then
    echo "❌ Fichier firestore.indexes.json non trouvé"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Se connecter à Firebase (si nécessaire)
echo "📱 Vérification de l'authentification Firebase..."
firebase login --no-localhost

# Déployer les index
echo "🚀 Déploiement des index Firestore..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ Index Firestore déployés avec succès!"
    echo ""
    echo "📋 Index ajoutés:"
    echo "  • roles: isActive + isSystemRole + name + __name__"
    echo "  • permissions: module + category + __name__"
    echo ""
    echo "⏳ Attendez quelques minutes que les index soient créés par Firebase."
    echo "🔄 Relancez ensuite votre application Flutter."
else
    echo "❌ Erreur lors du déploiement des index"
    echo ""
    echo "🔗 Vous pouvez aussi créer les index manuellement:"
    echo "1. Rôles: https://console.firebase.google.com/v1/r/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes?create_composite=Clxwcm9qZWN0cy9oanllMjV1OGl3bTBpMHpsczc4dXJmZnNjMGpjZ2ovZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JvbGVzL2luZGV4ZXMvXxABGgwKCGlzQWN0aXZlEAEaEAoMaXNTeXN0ZW1Sb2xlEAIaCAoEbmFtZRABGgwKCF9fbmFtZV9fEAE"
    echo "2. Permissions: https://console.firebase.google.com/v1/r/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes?create_composite=CmJwcm9qZWN0cy9oanllMjV1OGl3bTBpMHpsczc4dXJmZnNjMGpjZ2ovZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3Blcm1pc3Npb25zL2luZGV4ZXMvXxABGgoKBm1vZHVsZRABGgwKCGNhdGVnb3J5EAEaDAoIX19uYW1lX18QAQ"
    exit 1
fi

echo ""
echo "🎉 Configuration terminée!"