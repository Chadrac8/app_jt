#!/bin/bash

# Script de build optimisé pour app.jubiletabernacle.org
# Ce script configure et compile l'application Flutter Web pour le domaine personnalisé

echo "═══════════════════════════════════════════════════════════════"
echo "🏗️     BUILD OPTIMISÉ - JUBILÉ TABERNACLE APP              🏗️"
echo "═══════════════════════════════════════════════════════════════"
echo ""

DOMAIN="app.jubiletabernacle.org"
PROJECT_ID="hjye25u8iwm0i0zls78urffsc0jcgj"

echo "🎯 [BUILD] Configuration pour: https://$DOMAIN"
echo ""

# Étape 1: Vérification des prérequis
echo "📋 [ÉTAPE 1] Vérification des prérequis..."

if ! command -v flutter &> /dev/null; then
    echo "   ❌ Flutter non installé"
    exit 1
else
    echo "   ✅ Flutter installé"
fi

if ! command -v firebase &> /dev/null; then
    echo "   ❌ Firebase CLI non installé"
    exit 1
else
    echo "   ✅ Firebase CLI installé"
fi

echo ""

# Étape 2: Nettoyage
echo "🧹 [ÉTAPE 2] Nettoyage des builds précédents..."
if [ -d "build" ]; then
    rm -rf build/
    echo "   ✅ Dossier build supprimé"
else
    echo "   ℹ️  Aucun build précédent trouvé"
fi

flutter clean > /dev/null 2>&1
echo "   ✅ Cache Flutter nettoyé"
echo ""

# Étape 3: Installation des dépendances
echo "📦 [ÉTAPE 3] Installation des dépendances..."
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Dépendances installées"
else
    echo "   ❌ Erreur lors de l'installation des dépendances"
    exit 1
fi
echo ""

# Étape 4: Vérification de la configuration
echo "⚙️  [ÉTAPE 4] Vérification de la configuration..."

if grep -q "$DOMAIN" "lib/config/app_urls.dart"; then
    echo "   ✅ Configuration du domaine trouvée"
else
    echo "   ⚠️  Configuration du domaine non trouvée"
fi

if grep -q "Jubilé Tabernacle" "web/index.html"; then
    echo "   ✅ Métadonnées web configurées"
else
    echo "   ⚠️  Métadonnées web non configurées"
fi

echo ""

# Étape 5: Build de l'application
echo "🔨 [ÉTAPE 5] Compilation de l'application..."
echo "   📁 Cible: build/web/"
echo "   🌐 Domaine: $DOMAIN"
echo "   🎨 Mode: Release"
echo ""

flutter build web \
    --base-href "/" \
    --release \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false

if [ $? -eq 0 ]; then
    echo ""
    echo "   ✅ Compilation réussie!"
else
    echo ""
    echo "   ❌ Erreur lors de la compilation"
    exit 1
fi

echo ""

# Étape 6: Optimisations post-build
echo "⚡ [ÉTAPE 6] Optimisations post-build..."

# Vérifier que les fichiers essentiels existent
if [ -f "build/web/index.html" ]; then
    echo "   ✅ Index.html généré"
else
    echo "   ❌ Index.html manquant"
    exit 1
fi

if [ -f "build/web/main.dart.js" ]; then
    echo "   ✅ Code JavaScript généré"
    MAIN_JS_SIZE=$(du -h "build/web/main.dart.js" | cut -f1)
    echo "   📊 Taille du JS principal: $MAIN_JS_SIZE"
else
    echo "   ❌ Code JavaScript manquant"
    exit 1
fi

if [ -f "build/web/manifest.json" ]; then
    echo "   ✅ Manifest.json généré"
else
    echo "   ❌ Manifest.json manquant"
fi

echo ""

# Étape 7: Statistiques du build
echo "📊 [ÉTAPE 7] Statistiques du build..."

TOTAL_SIZE=$(du -sh build/web/ | cut -f1)
FILE_COUNT=$(find build/web/ -type f | wc -l | tr -d ' ')

echo "   📁 Taille totale: $TOTAL_SIZE"
echo "   📄 Nombre de fichiers: $FILE_COUNT"

if [ -d "build/web/assets" ]; then
    ASSETS_SIZE=$(du -sh build/web/assets/ | cut -f1)
    echo "   🎨 Taille des assets: $ASSETS_SIZE"
fi

echo ""

# Étape 8: Vérifications finales
echo "🔍 [ÉTAPE 8] Vérifications finales..."

# Vérifier que le titre est correct
if grep -q "Jubilé Tabernacle" "build/web/index.html"; then
    echo "   ✅ Titre de l'application correct"
else
    echo "   ⚠️  Titre de l'application non mis à jour"
fi

# Vérifier les métadonnées Open Graph
if grep -q "$DOMAIN" "build/web/index.html"; then
    echo "   ✅ URLs Open Graph configurées"
else
    echo "   ⚠️  URLs Open Graph non configurées"
fi

echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "🏛️  [JUBILÉ] BUILD TERMINÉ AVEC SUCCÈS!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Application compilée pour: https://$DOMAIN"
echo "📁 Fichiers générés dans: build/web/"
echo "📊 Taille totale: $TOTAL_SIZE"
echo ""
echo "🚀 PROCHAINES ÉTAPES:"
echo "1. Déployez avec: firebase deploy --only hosting"
echo "2. Testez sur: https://$DOMAIN"
echo "3. Vérifiez les formulaires et leurs URLs"
echo ""
echo "🔗 Commande de déploiement rapide:"
echo "   firebase deploy --only hosting --project $PROJECT_ID"
echo ""
echo "🏛️  [JUBILÉ] Build optimisé terminé! 🙏"
