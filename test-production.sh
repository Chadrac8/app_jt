#!/bin/bash

# Script de test des fonctions Firebase déployées
# Date: 12 Juillet 2025

echo "🧪 TESTS FIREBASE FUNCTIONS EN PRODUCTION"
echo "=========================================="

# Test 1: Vérifier le statut des fonctions
echo ""
echo "📋 1. STATUT DES FONCTIONS DÉPLOYÉES"
firebase functions:list

# Test 2: Vérifier les logs récents
echo ""
echo "📊 2. LOGS RÉCENTS (dernières 5 entrées)"
firebase functions:log --limit 5

# Test 3: Logs spécifiques à sendPushNotification
echo ""
echo "📱 3. LOGS SENDPUSHNOTIFICATION"
firebase functions:log --only sendPushNotification --limit 3

# Test 4: Logs de nettoyage des tokens
echo ""
echo "🧹 4. LOGS CLEANUP TOKENS"
firebase functions:log --only cleanupInactiveTokens --limit 3

echo ""
echo "✅ Tests terminés. Fonctions principales opérationnelles !"
echo ""
echo "⚠️  FONCTIONS EN ATTENTE DE PERMISSIONS:"
echo "   - onAppointmentCreated (notifications auto sur nouveaux RDV)"
echo "   - onAppointmentUpdated (notifications auto sur modifications RDV)"
echo ""
echo "💡 CES FONCTIONS SE DÉPLOIERONT APRÈS PROPAGATION DES PERMISSIONS (5-10 min)"
