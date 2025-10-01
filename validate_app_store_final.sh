#!/bin/bash

# Script de Validation App Store pour Jubilé Tabernacle
# Ce script vérifie la conformité avant soumission

echo "🍎 VALIDATION APP STORE - JUBILÉ TABERNACLE"
echo "=========================================="

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

echo -e "\n📋 1. VÉRIFICATION DES FICHIERS REQUIS"
echo "======================================"

# Vérification des fichiers essentiels
files_required=(
    "pubspec.yaml"
    "ios/Runner/Info.plist"
    "assets/app_icon.png"
    "privacy_policy.html"
)

for file in "${files_required[@]}"; do
    if [ -f "$file" ]; then
        echo -e "✅ ${GREEN}$file${NC} - Présent"
    else
        echo -e "❌ ${RED}$file${NC} - MANQUANT"
        ((errors++))
    fi
done

echo -e "\n📱 2. VÉRIFICATION DE LA CONFIGURATION iOS"
echo "======================================="

# Vérification Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    echo "🔍 Analyse du fichier Info.plist..."
    
    # Vérification CFBundleDisplayName
    if grep -q "CFBundleDisplayName" "ios/Runner/Info.plist"; then
        display_name=$(grep -A1 "CFBundleDisplayName" "ios/Runner/Info.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo -e "✅ ${GREEN}Nom d'affichage:${NC} $display_name"
    else
        echo -e "⚠️  ${YELLOW}CFBundleDisplayName manquant${NC}"
        ((warnings++))
    fi
    
    # Vérification des permissions
    permissions=(
        "NSCameraUsageDescription"
        "NSPhotoLibraryUsageDescription"
        "NSMicrophoneUsageDescription"
        "NSLocationWhenInUseUsageDescription"
    )
    
    for permission in "${permissions[@]}"; do
        if grep -q "$permission" "ios/Runner/Info.plist"; then
            echo -e "✅ ${GREEN}$permission${NC} - Définie"
        else
            echo -e "⚠️  ${YELLOW}$permission${NC} - Manquante"
            ((warnings++))
        fi
    done
fi

echo -e "\n🔧 3. VÉRIFICATION DE LA CONFIGURATION FLUTTER"
echo "============================================"

# Vérification pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    echo "🔍 Analyse du fichier pubspec.yaml..."
    
    # Vérification de la version
    if grep -q "version:" "pubspec.yaml"; then
        version=$(grep "version:" "pubspec.yaml" | sed 's/version: //')
        echo -e "✅ ${GREEN}Version:${NC} $version"
        
        # Vérification du format version+build
        if [[ $version =~ \+[0-9]+$ ]]; then
            echo -e "✅ ${GREEN}Format version+build correct${NC}"
        else
            echo -e "❌ ${RED}Format version+build incorrect (ex: 1.0.0+1)${NC}"
            ((errors++))
        fi
    fi
    
    # Vérification de la description
    if grep -q "description:" "pubspec.yaml"; then
        description=$(grep "description:" "pubspec.yaml" | sed 's/description: //')
        desc_length=${#description}
        echo -e "✅ ${GREEN}Description présente${NC} ($desc_length caractères)"
        
        if [ $desc_length -lt 50 ]; then
            echo -e "⚠️  ${YELLOW}Description courte (recommandé: 80+ caractères)${NC}"
            ((warnings++))
        fi
    fi
fi

echo -e "\n🎨 4. VÉRIFICATION DES ASSETS"
echo "=========================="

# Vérification de l'icône
if [ -f "assets/app_icon.png" ]; then
    echo -e "✅ ${GREEN}Icône d'application présente${NC}"
    
    # Vérification de la taille (optionnel, nécessite ImageMagick)
    if command -v identify &> /dev/null; then
        icon_size=$(identify -format "%wx%h" "assets/app_icon.png")
        echo -e "📏 ${GREEN}Taille de l'icône:${NC} $icon_size"
        
        if [[ $icon_size == "1024x1024" ]]; then
            echo -e "✅ ${GREEN}Taille d'icône correcte pour l'App Store${NC}"
        else
            echo -e "⚠️  ${YELLOW}Taille recommandée: 1024x1024${NC}"
            ((warnings++))
        fi
    fi
fi

echo -e "\n🛡️  5. VÉRIFICATION DE LA SÉCURITÉ"
echo "==============================="

# Vérification HTTPS
if grep -r "http://" lib/ 2>/dev/null | grep -v "localhost" | grep -v "127.0.0.1"; then
    echo -e "❌ ${RED}URLs HTTP non-sécurisées détectées${NC}"
    ((errors++))
else
    echo -e "✅ ${GREEN}Aucune URL HTTP non-sécurisée détectée${NC}"
fi

# Vérification des clés de test Firebase
if find . -name "*.dart" -exec grep -l "test" {} \; | grep -v test/ | head -1 > /dev/null; then
    echo -e "⚠️  ${YELLOW}Vérifiez que les clés de production Firebase sont utilisées${NC}"
    ((warnings++))
fi

echo -e "\n📝 6. VÉRIFICATION DE LA POLITIQUE DE CONFIDENTIALITÉ"
echo "================================================="

if [ -f "privacy_policy.html" ]; then
    echo -e "✅ ${GREEN}Politique de confidentialité présente${NC}"
    
    # Vérification de la longueur
    policy_length=$(wc -c < "privacy_policy.html")
    if [ $policy_length -gt 1000 ]; then
        echo -e "✅ ${GREEN}Politique de confidentialité complète${NC}"
    else
        echo -e "⚠️  ${YELLOW}Politique de confidentialité courte${NC}"
        ((warnings++))
    fi
fi

echo -e "\n🔍 7. COMPILATION ET TESTS"
echo "======================="

echo "🔄 Test de compilation Flutter..."
if flutter analyze --fatal-infos > /dev/null 2>&1; then
    echo -e "✅ ${GREEN}Analyse Flutter réussie${NC}"
else
    echo -e "⚠️  ${YELLOW}Avertissements Flutter détectés${NC}"
    ((warnings++))
fi

# Test de build (optionnel)
read -p "Voulez-vous tester la compilation iOS ? (y/N): " test_build
if [[ $test_build =~ ^[Yy]$ ]]; then
    echo "🔄 Test de compilation iOS..."
    if flutter build ios --release --no-codesign > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}Compilation iOS réussie${NC}"
    else
        echo -e "❌ ${RED}Échec de la compilation iOS${NC}"
        ((errors++))
    fi
fi

echo -e "\n📊 RÉSUMÉ DE LA VALIDATION"
echo "========================"

echo -e "Erreurs critiques: ${RED}$errors${NC}"
echo -e "Avertissements: ${YELLOW}$warnings${NC}"

if [ $errors -eq 0 ]; then
    if [ $warnings -eq 0 ]; then
        echo -e "\n🎉 ${GREEN}PARFAIT !${NC} Votre application est prête pour l'App Store"
        echo -e "📋 ${GREEN}Actions suivantes:${NC}"
        echo "   1. Générer les captures d'écran"
        echo "   2. Créer l'archive iOS dans Xcode"
        echo "   3. Soumettre via App Store Connect"
    else
        echo -e "\n✅ ${GREEN}PRÊT AVEC AVERTISSEMENTS${NC}"
        echo -e "📋 ${YELLOW}Recommandations:${NC} Corrigez les avertissements pour optimiser l'approbation"
    fi
else
    echo -e "\n❌ ${RED}ERREURS DÉTECTÉES${NC}"
    echo -e "📋 ${RED}Actions requises:${NC} Corrigez les erreurs avant soumission"
fi

exit $errors