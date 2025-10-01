#!/bin/bash

# Script de déploiement Play Store - Jubilé Tabernacle
# Usage: ./deploy_play_store.sh

set -e

echo "🚀 DÉPLOIEMENT PLAY STORE - JUBILÉ TABERNACLE"
echo "============================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifications préliminaires
print_step "Vérification de l'environnement..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter n'est pas installé ou pas dans le PATH"
    exit 1
fi

if [ ! -f "android/key.properties" ]; then
    print_error "Fichier android/key.properties manquant"
    print_warning "Créez le fichier avec vos clés de signature"
    exit 1
fi

if [ ! -f "android/app/upload-keystore.jks" ]; then
    print_error "Keystore manquant : android/app/upload-keystore.jks"
    exit 1
fi

print_success "Environnement vérifié"

# Nettoyage
print_step "Nettoyage des builds précédents..."
flutter clean
rm -rf build/
print_success "Nettoyage terminé"

# Mise à jour des dépendances
print_step "Mise à jour des dépendances..."
flutter pub get
print_success "Dépendances mises à jour"

# Vérification de la conformité
print_step "Vérification de la conformité Play Store..."

# Vérifier les API levels
if ! grep -q "targetSdkVersion = 34" android/app/build.gradle; then
    print_error "targetSdkVersion doit être 34 pour Play Store 2025"
    exit 1
fi

# Vérifier la configuration AAB
if ! grep -q "minifyEnabled = true" android/app/build.gradle; then
    print_warning "Minification non activée (recommandée pour Play Store)"
fi

print_success "Configuration conforme"

# Analyse statique
print_step "Analyse statique du code..."
flutter analyze --no-fatal-infos
print_success "Analyse terminée"

# Tests (si disponibles)
if [ -d "test" ] && [ "$(ls -A test)" ]; then
    print_step "Exécution des tests..."
    flutter test
    print_success "Tests réussis"
fi

# Build de l'App Bundle
print_step "Génération de l'App Bundle (AAB)..."
flutter build appbundle --release --verbose

if [ $? -eq 0 ]; then
    print_success "App Bundle généré avec succès"
else
    print_error "Échec de la génération de l'App Bundle"
    exit 1
fi

# Vérifications post-build
print_step "Vérifications post-build..."

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    print_success "App Bundle trouvé : $AAB_SIZE"
    
    # Affichage du chemin complet
    FULL_PATH=$(pwd)/$AAB_PATH
    echo -e "${BLUE}📁 Chemin complet : $FULL_PATH${NC}"
else
    print_error "App Bundle non trouvé à l'emplacement attendu"
    exit 1
fi

# Informations de déploiement
echo ""
echo "🎉 BUILD PLAY STORE TERMINÉ AVEC SUCCÈS !"
echo "========================================"
echo ""
print_step "Prochaines étapes :"
echo "1. 📤 Connectez-vous à Google Play Console"
echo "2. 🏪 Allez dans votre application 'Jubilé Tabernacle'"
echo "3. 📋 Section 'Release' > 'Production'"
echo "4. 📦 Uploadez le fichier : $AAB_PATH"
echo "5. 📝 Complétez les informations requises :"
echo "   - Notes de release"
echo "   - Captures d'écran (minimum 2)"
echo "   - Description de l'app"
echo "   - Politique de confidentialité : https://chadrac8.github.io/app_jt/"
echo "6. 🔍 Soumettez pour révision"
echo ""
print_warning "Délai de révision : 1-3 jours ouvrés"
print_warning "Vérifiez que tous les champs obligatoires sont remplis"
echo ""
print_success "Bonne chance pour votre soumission Play Store ! 🚀"