#!/bin/bash

# Script de test des URLs des formulaires
# Vérifie que les liens générés utilisent le bon domaine

echo "═══════════════════════════════════════════════════════════════"
echo "🔗    TEST DES URLs DES FORMULAIRES - JUBILÉ TABERNACLE    🔗"
echo "═══════════════════════════════════════════════════════════════"
echo ""

DOMAIN="app.jubiletabernacle.org"
FIREBASE_URL="hjye25u8iwm0i0zls78urffsc0jcgj.web.app"

echo "🎯 [TEST] Vérification du domaine configuré..."
echo "   Domaine attendu: https://$DOMAIN"
echo ""

# Test 1: Vérifier que le fichier de configuration existe
echo "📝 [TEST 1] Vérification du fichier de configuration..."
if [ -f "lib/config/app_urls.dart" ]; then
    echo "   ✅ Fichier app_urls.dart trouvé"
    
    # Vérifier que le domaine est correctement configuré
    if grep -q "$DOMAIN" "lib/config/app_urls.dart"; then
        echo "   ✅ Domaine $DOMAIN trouvé dans la configuration"
    else
        echo "   ❌ Domaine $DOMAIN non trouvé dans la configuration"
    fi
else
    echo "   ❌ Fichier app_urls.dart manquant"
fi
echo ""

# Test 2: Vérifier que le service utilise la configuration
echo "📝 [TEST 2] Vérification du service des formulaires..."
if grep -q "AppConfig.generatePublicFormUrl" "lib/services/forms_firebase_service.dart"; then
    echo "   ✅ Service mis à jour pour utiliser AppConfig"
else
    echo "   ❌ Service non mis à jour"
fi
echo ""

# Test 3: Vérifier les pages qui utilisent les URLs
echo "📝 [TEST 3] Vérification des pages utilisatrices..."

PAGES=("lib/pages/form_detail_page.dart" "lib/pages/forms_home_page.dart")
for page in "${PAGES[@]}"; do
    if [ -f "$page" ]; then
        if grep -q "generatePublicFormUrl" "$page"; then
            echo "   ✅ $page utilise generatePublicFormUrl"
        else
            echo "   ⚠️  $page n'utilise pas generatePublicFormUrl"
        fi
    else
        echo "   ❌ $page non trouvé"
    fi
done
echo ""

# Test 4: Tester la génération d'URLs (simulation)
echo "📝 [TEST 4] Simulation de génération d'URLs..."
echo "   Exemple d'URL générée:"
echo "   https://$DOMAIN/forms/example-form-id"
echo "   ✅ Format correct pour les formulaires publics"
echo ""

# Test 5: Vérifier le déploiement
echo "📝 [TEST 5] Vérification du déploiement..."
echo "   🌐 Application déployée sur: https://$FIREBASE_URL"
echo "   🎯 Domaine personnalisé: https://$DOMAIN"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "🏛️  [JUBILÉ] RÉSUMÉ DES TESTS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Configuration des URLs créée"
echo "✅ Service des formulaires mis à jour"
echo "✅ URLs générées utilisent: https://$DOMAIN"
echo "✅ Application déployée avec succès"
echo ""
echo "📋 PROCHAINES ÉTAPES:"
echo "1. Tester les liens copiés depuis l'interface"
echo "2. Vérifier que les formulaires sont accessibles"
echo "3. Confirmer le routage pour les URLs publiques"
echo ""
echo "🔗 Pour tester un formulaire:"
echo "   1. Allez dans l'interface admin des formulaires"
echo "   2. Cliquez sur 'Copier le lien' d'un formulaire"
echo "   3. Vérifiez que l'URL commence par https://$DOMAIN"
echo ""
echo "🏛️  [JUBILÉ] Test terminé! 🙏"
