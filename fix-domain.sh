#!/bin/bash

# Script pour configurer le domaine personnalisé app.jubiletabernacle.org dans Firebase

echo "═══════════════════════════════════════════════════════════════"
echo "🔧    CONFIGURATION DOMAINE FIREBASE - JUBILÉ TABERNACLE    🔧"
echo "═══════════════════════════════════════════════════════════════"
echo ""

DOMAIN="app.jubiletabernacle.org"
SITE_ID="hjye25u8iwm0i0zls78urffsc0jcgj"

echo "🎯 [CONFIG] Domaine à configurer: $DOMAIN"
echo "🏗️  [CONFIG] Site Firebase: $SITE_ID"
echo ""

# Étape 1: Diagnostic du problème actuel
echo "🔍 [ÉTAPE 1] Diagnostic du problème actuel..."

echo "   📊 État actuel du domaine:"
CURRENT_IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}')
echo "   📍 IP actuelle: $CURRENT_IP"

echo "   📊 Test HTTP:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "   📈 Code de réponse: $HTTP_STATUS"

echo "   📊 Serveur actuel:"
SERVER_INFO=$(curl -s -I https://$DOMAIN | grep -i "server\|x-powered-by\|platform" | head -3)
echo "$SERVER_INFO"

echo ""

# Étape 2: Vérification Firebase
echo "🔥 [ÉTAPE 2] Vérification de la configuration Firebase..."

echo "   📋 Sites Firebase configurés:"
firebase hosting:sites:list

echo ""

# Étape 3: Instructions pour configurer le domaine
echo "📝 [ÉTAPE 3] Instructions pour configurer le domaine personnalisé..."
echo ""
echo "   🎯 PROBLÈME IDENTIFIÉ:"
echo "      Le domaine $DOMAIN pointe actuellement vers Hostinger/PHP"
echo "      Il doit être configuré pour pointer vers Firebase Hosting"
echo ""
echo "   🔧 SOLUTION - Méthode 1 (Console Firebase):"
echo "      1. Allez sur: https://console.firebase.google.com/project/$SITE_ID/hosting"
echo "      2. Cliquez sur 'Ajouter un domaine personnalisé'"
echo "      3. Entrez: $DOMAIN"
echo "      4. Suivez les instructions de vérification DNS"
echo ""
echo "   🔧 SOLUTION - Méthode 2 (DNS Direct):"
echo "      Configurez ces enregistrements DNS chez votre fournisseur:"
echo ""
echo "      Type: A"
echo "      Nom: app"
echo "      Valeur: 199.36.158.100"
echo ""
echo "      OU"
echo ""
echo "      Type: CNAME"
echo "      Nom: app"
echo "      Valeur: $SITE_ID.web.app"
echo ""
echo "   ⚠️  IMPORTANT:"
echo "      - Supprimez d'abord la configuration Hostinger actuelle"
echo "      - La propagation DNS peut prendre 24-48h"
echo "      - Firebase configurera automatiquement le SSL"
echo ""

# Étape 4: Test de l'URL Firebase directe
echo "🧪 [ÉTAPE 4] Test de l'URL Firebase directe..."
FIREBASE_URL="https://$SITE_ID.web.app"
echo "   🔗 Test de: $FIREBASE_URL"

FIREBASE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $FIREBASE_URL)
if [ "$FIREBASE_STATUS" = "200" ]; then
    echo "   ✅ Application Firebase accessible ($FIREBASE_STATUS)"
else
    echo "   ❌ Application Firebase non accessible ($FIREBASE_STATUS)"
fi

echo ""

# Étape 5: Instructions de vérification
echo "🔍 [ÉTAPE 5] Vérification après configuration..."
echo ""
echo "   Une fois le domaine configuré, utilisez ces commandes:"
echo ""
echo "   # Vérifier la propagation DNS:"
echo "   nslookup $DOMAIN"
echo ""
echo "   # Tester l'accessibilité:"
echo "   curl -I https://$DOMAIN"
echo ""
echo "   # Vérifier que Firebase répond:"
echo "   curl -s https://$DOMAIN | grep -i flutter"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "🏛️  [JUBILÉ] RÉSUMÉ DE LA CONFIGURATION REQUISE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "❌ PROBLÈME ACTUEL:"
echo "   $DOMAIN → Serveur Hostinger/PHP"
echo ""
echo "✅ SOLUTION REQUISE:"
echo "   $DOMAIN → Firebase Hosting ($SITE_ID.web.app)"
echo ""
echo "🔧 ACTIONS À EFFECTUER:"
echo "   1. Configurer le domaine dans Firebase Console"
echo "   2. OU modifier les DNS pour pointer vers Firebase"
echo "   3. Attendre la propagation DNS"
echo "   4. Vérifier avec ./verify-jubile.sh"
echo ""
echo "🔗 LIENS UTILES:"
echo "   • Console Firebase: https://console.firebase.google.com/project/$SITE_ID/hosting"
echo "   • App actuelle: https://$SITE_ID.web.app"
echo "   • Documentation: https://firebase.google.com/docs/hosting/custom-domain"
echo ""
echo "🏛️  [JUBILÉ] Configuration en attente de votre action! 🙏"
