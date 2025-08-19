#!/bin/bash

echo "🔧 Configuration de l'authentification Firebase..."

# Vérifier si Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé. Installez-le avec: npm install -g firebase-tools"
    exit 1
fi

# Se connecter au projet
echo "📱 Configuration du projet Firebase..."
firebase use hjye25u8iwm0i0zls78urffsc0jcgj

# Note: La configuration de l'authentification anonyme doit être faite manuellement
# dans la console Firebase car il n'y a pas de commande CLI directe pour cela.

echo "⚠️  ÉTAPES MANUELLES REQUISES:"
echo ""
echo "1. Ouvrez la console Firebase: https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/authentication/providers"
echo ""
echo "2. Dans l'onglet 'Sign-in method', activez 'Anonymous' :"
echo "   - Cliquez sur 'Anonymous'"
echo "   - Activez le bouton 'Enable'"
echo "   - Cliquez sur 'Save'"
echo ""
echo "3. Une fois activé, revenez tester l'application"
echo ""
echo "🔗 Lien direct: https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/authentication/providers"
echo ""

# Ouvrir automatiquement le lien dans le navigateur (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🌐 Ouverture automatique de la console Firebase..."
    open "https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/authentication/providers"
fi

echo "✅ Une fois l'authentification anonyme activée, les utilisateurs pourront créer et modifier des thèmes!"
