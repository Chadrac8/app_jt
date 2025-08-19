#!/bin/bash

# Script de diagnostic et correction des tokens FCM invalides
# Usage: ./fix_fcm_tokens.sh

echo "🔧 Script de correction des tokens FCM invalides"
echo "================================================="

# Fonction pour supprimer les tokens invalides de Firebase
cleanup_firebase_tokens() {
    echo "🧹 Nettoyage des tokens invalides dans Firebase..."
    
    # Ouvrir la console Firebase dans le navigateur
    echo "📱 Ouvrez Firebase Console > Firestore Database > Collection 'fcm_tokens'"
    echo "❌ Supprimez tous les documents qui ont des tokens invalides"
    echo "⚠️  Un token valide fait plus de 100 caractères et ne contient pas d'espaces"
    
    # URL directe vers la console
    echo "🌐 URL: https://console.firebase.google.com/"
}

# Fonction pour vérifier les certificats iOS
check_ios_certificates() {
    echo "📱 Vérification des certificats iOS..."
    echo "1. ✅ Assurez-vous que les certificats APNS sont configurés dans Firebase Console"
    echo "2. ✅ Bundle ID doit correspondre exactement"
    echo "3. ✅ Provisioning profile doit avoir les notifications push activées"
    echo "4. ✅ Capability 'Push Notifications' doit être activée dans Xcode"
}

# Fonction pour tester les notifications
test_notifications() {
    echo "🧪 Test des notifications..."
    echo "1. 📲 Désinstallez l'app complètement de l'appareil"
    echo "2. 🔄 Réinstallez l'app depuis Xcode"
    echo "3. 🔔 Acceptez les permissions de notification"
    echo "4. ⏱️  Attendez 30 secondes pour la génération du token"
    echo "5. ✉️  Testez l'envoi d'une notification"
}

# Fonction principale
main() {
    echo "🚀 Début du diagnostic..."
    
    cleanup_firebase_tokens
    echo ""
    check_ios_certificates
    echo ""
    test_notifications
    
    echo ""
    echo "✅ Diagnostic terminé!"
    echo "📞 Si le problème persiste, vérifiez la configuration APNS dans Firebase Console"
}

# Exécuter le script
main
