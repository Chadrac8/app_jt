#!/bin/bash

# Script de déploiement de la synchronisation cloud
# Module Search - William Branham Sermons

echo "🚀 Déploiement de la synchronisation cloud..."
echo ""

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé"
    echo "   Installation: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI détecté"
echo ""

# Vérifier que l'utilisateur est connecté
if ! firebase projects:list &> /dev/null; then
    echo "❌ Non connecté à Firebase"
    echo "   Connexion: firebase login"
    exit 1
fi

echo "✅ Connecté à Firebase"
echo ""

# Afficher le projet actuel
PROJECT=$(firebase use)
echo "📦 Projet Firebase: $PROJECT"
echo ""

# Confirmation
read -p "Déployer les règles et index Firestore pour ce projet ? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

echo ""
echo "⏳ Déploiement des règles Firestore..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Règles Firestore déployées avec succès"
else
    echo "❌ Erreur lors du déploiement des règles"
    exit 1
fi

echo ""
echo "⏳ Déploiement des index Firestore..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ Index Firestore déployés avec succès"
    echo ""
    echo "⚠️  Note: La création des index peut prendre 5-10 minutes"
    echo "   Vérifiez le statut dans la console Firebase:"
    echo "   https://console.firebase.google.com/project/$PROJECT/firestore/indexes"
else
    echo "❌ Erreur lors du déploiement des index"
    exit 1
fi

echo ""
echo "🎉 Déploiement terminé avec succès !"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Attendre que les index soient créés (5-10 min)"
echo "   2. Tester la synchronisation sur un appareil"
echo "   3. Vérifier les logs dans la console Firebase"
echo ""
echo "📚 Documentation:"
echo "   - lib/modules/search/CLOUD_SYNC_DOCUMENTATION.md"
echo "   - lib/modules/search/CLOUD_SYNC_IMPLEMENTATION.md"
echo ""
