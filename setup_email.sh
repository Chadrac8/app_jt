#!/bin/bash

echo "🔧 Configuration de l'email automatique pour Jubilé Tabernacle"
echo "================================================================"
echo ""

echo "📋 Étapes à suivre :"
echo ""
echo "1. 📧 Créer un email Gmail dédié (ex: jubile.tabernacle.notification@gmail.com)"
echo "2. 🔐 Activer la validation en 2 étapes sur ce compte"
echo "3. 🗝️  Créer un mot de passe d'application :"
echo "   • Allez sur myaccount.google.com"
echo "   • Sécurité → Validation en 2 étapes → Mots de passe des applications"
echo "   • Créez un mot de passe pour 'Jubilé Tabernacle'"
echo ""

read -p "4. 📝 Entrez l'email Gmail à utiliser (ex: jubile.tabernacle.notification@gmail.com): " EMAIL_USER
read -s -p "5. 🔑 Entrez le mot de passe d'application (sera masqué): " EMAIL_PASSWORD
echo ""
echo ""

# Mise à jour de la fonction avec les vrais credentials
echo "🔄 Mise à jour de la fonction Firebase..."

# Remplacer les credentials dans le fichier
sed -i '' "s/jubile.tabernacle.notification@gmail.com/$EMAIL_USER/g" ../functions/index.js
sed -i '' "s/test_password_to_replace/$EMAIL_PASSWORD/g" ../functions/index.js

echo "✅ Credentials mis à jour dans le code"

# Déployer la fonction
echo "🚀 Déploiement de la fonction..."
firebase deploy --only functions:onContactMessageCreated

echo ""
echo "🎉 Configuration terminée !"
echo ""
echo "✅ Les messages de contact seront maintenant automatiquement envoyés à:"
echo "   📧 contact@jubiletabernacle.org"
echo ""
echo "📱 Testez en envoyant un message depuis l'application"
echo "🔍 Vérifiez les logs avec: firebase functions:log --only onContactMessageCreated"
