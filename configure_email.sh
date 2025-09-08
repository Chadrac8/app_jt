#!/bin/bash

# Script de configuration des paramètres email pour Firebase Functions
# Ce script configure les paramètres nécessaires pour l'envoi d'emails

echo "🔧 Configuration des paramètres email pour Firebase Functions..."
echo ""

# Demander le mot de passe de l'email (utiliser un mot de passe d'application pour Gmail)
echo "⚠️  Important: Utilisez un mot de passe d'application Gmail, pas votre mot de passe principal"
echo "   Pour créer un mot de passe d'application:"
echo "   1. Allez dans votre compte Google (contact@jubiletabernacle.org)"
echo "   2. Sécurité > Validation en 2 étapes"
echo "   3. Mots de passe des applications"
echo "   4. Générez un nouveau mot de passe pour 'Jubilé Tabernacle'"
echo ""

read -s -p "Entrez le mot de passe d'application Gmail pour contact@jubiletabernacle.org: " EMAIL_PASSWORD
echo ""

# Déployer avec les paramètres
echo "🚀 Déploiement de la fonction avec les paramètres email..."
firebase deploy --only functions:onContactMessageCreated \
  --env EMAIL_PASSWORD="$EMAIL_PASSWORD" \
  --env EMAIL_USER="contact@jubiletabernacle.org"

echo ""
echo "✅ Configuration terminée!"
echo ""
echo "� Les nouveaux messages de contact seront maintenant envoyés automatiquement à:"
echo "   contact@jubiletabernacle.org"
echo ""
echo "🧪 Pour tester:"
echo "   1. Envoyez un message depuis l'application"
echo "   2. Vérifiez les logs: firebase functions:log --only onContactMessageCreated"
echo "   3. Vérifiez votre boîte email"
