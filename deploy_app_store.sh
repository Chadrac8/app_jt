#!/bin/bash

# ============================================================================
# 🍎 SCRIPT DE DÉPLOIEMENT APP STORE - JUBILÉ TABERNACLE
# ============================================================================
# Ce script automatise la build et l'upload de l'application iOS vers
# App Store Connect pour soumission à l'App Store
# ============================================================================

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Jubilé Tabernacle"
BUNDLE_ID="org.jubiletabernacle.app"
SCHEME="Runner"
WORKSPACE="ios/Runner.xcworkspace"
BUILD_DIR="build/ios/archive"

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║    🍎  DÉPLOIEMENT APP STORE - JUBILÉ TABERNACLE  🍎      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# ÉTAPE 1: VÉRIFICATIONS PRÉLIMINAIRES
# ============================================================================
echo -e "${BOLD}${BLUE}📋 ÉTAPE 1/7: Vérifications préliminaires${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erreur: pubspec.yaml non trouvé. Êtes-vous dans le bon répertoire ?${NC}"
    exit 1
fi

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter n'est pas installé ou pas dans le PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter détecté:${NC} $(flutter --version | head -n 1)"

# Vérifier Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode n'est pas installé${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Xcode détecté:${NC} $(xcodebuild -version | head -n 1)"

# Vérifier la version dans pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Version non trouvée dans pubspec.yaml${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Version de l'app:${NC} $VERSION"

# Extraire version et build number
VERSION_NUMBER=$(echo $VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
echo -e "${CYAN}   • Version number: $VERSION_NUMBER${NC}"
echo -e "${CYAN}   • Build number: $BUILD_NUMBER${NC}"

echo ""

# ============================================================================
# ÉTAPE 2: NETTOYAGE
# ============================================================================
echo -e "${BOLD}${BLUE}🧹 ÉTAPE 2/7: Nettoyage des builds précédents${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}🗑️  Nettoyage de Flutter...${NC}"
flutter clean

echo -e "${YELLOW}🗑️  Suppression du dossier build...${NC}"
rm -rf build/

echo -e "${YELLOW}🗑️  Nettoyage des pods iOS...${NC}"
cd ios
rm -rf Pods/ Podfile.lock .symlinks/
cd ..

echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""

# ============================================================================
# ÉTAPE 3: RÉCUPÉRATION DES DÉPENDANCES
# ============================================================================
echo -e "${BOLD}${BLUE}📦 ÉTAPE 3/7: Installation des dépendances${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}📥 flutter pub get...${NC}"
flutter pub get

echo -e "${YELLOW}📥 Installation des CocoaPods...${NC}"
cd ios
pod install --repo-update
cd ..

echo -e "${GREEN}✅ Dépendances installées${NC}"
echo ""

# ============================================================================
# ÉTAPE 4: BUILD DE L'APPLICATION
# ============================================================================
echo -e "${BOLD}${BLUE}🔨 ÉTAPE 4/7: Build de l'application iOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}⚙️  Génération du code (si nécessaire)...${NC}"
if [ -d "lib/generated" ]; then
    flutter pub run build_runner build --delete-conflicting-outputs || true
fi

echo -e "${YELLOW}🏗️  Build Flutter pour iOS (mode release)...${NC}"
flutter build ios --release --no-codesign

echo -e "${GREEN}✅ Build Flutter terminé${NC}"
echo ""

# ============================================================================
# ÉTAPE 5: ARCHIVAGE XCODE
# ============================================================================
echo -e "${BOLD}${BLUE}📦 ÉTAPE 5/7: Archivage Xcode${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
echo -e "${YELLOW}📦 Création de l'archive Xcode...${NC}"
echo -e "${CYAN}   Archive: $ARCHIVE_PATH${NC}"

# Créer le répertoire d'archive
mkdir -p build/ios/archive

# Archiver avec xcodebuild
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="VOTRE_TEAM_ID" \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    | xcpretty || xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="VOTRE_TEAM_ID" \
    CODE_SIGN_IDENTITY="Apple Distribution"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}❌ Erreur: L'archive n'a pas été créée${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive créée avec succès${NC}"
echo ""

# ============================================================================
# ÉTAPE 6: EXPORT POUR APP STORE
# ============================================================================
echo -e "${BOLD}${BLUE}📤 ÉTAPE 6/7: Export pour App Store${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

IPA_PATH="build/ios/ipa"
mkdir -p "$IPA_PATH"

# Créer le fichier ExportOptions.plist
EXPORT_OPTIONS_PATH="build/ios/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>VOTRE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>match AppStore $BUNDLE_ID</string>
    </dict>
</dict>
</plist>
EOF

echo -e "${YELLOW}📤 Export de l'archive vers IPA...${NC}"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$IPA_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates \
    | xcpretty || xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$IPA_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates

if [ ! -f "$IPA_PATH/Runner.ipa" ]; then
    echo -e "${RED}❌ Erreur: Le fichier IPA n'a pas été créé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ IPA créé avec succès${NC}"
echo -e "${CYAN}   Fichier: $IPA_PATH/Runner.ipa${NC}"

# Afficher la taille du fichier
IPA_SIZE=$(du -h "$IPA_PATH/Runner.ipa" | cut -f1)
echo -e "${CYAN}   Taille: $IPA_SIZE${NC}"
echo ""

# ============================================================================
# ÉTAPE 7: VALIDATION ET UPLOAD
# ============================================================================
echo -e "${BOLD}${BLUE}☁️  ÉTAPE 7/7: Validation et Upload vers App Store Connect${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}⚠️  IMPORTANT: Vous devez avoir un compte Apple Developer${NC}"
echo -e "${YELLOW}⚠️  et avoir créé l'app dans App Store Connect${NC}"
echo ""

# Demander si l'utilisateur veut valider et uploader
read -p "$(echo -e ${CYAN}Voulez-vous valider et uploader vers App Store Connect ? [o/N]:${NC} )" -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]]; then
    # Vérifier si altool est disponible
    if command -v xcrun altool &> /dev/null; then
        echo -e "${YELLOW}🔍 Validation de l'IPA...${NC}"
        
        read -p "$(echo -e ${CYAN}Email Apple ID:${NC} )" APPLE_ID
        echo -e "${CYAN}Mot de passe spécifique à l'app (depuis appleid.apple.com):${NC}"
        read -s APP_PASSWORD
        echo ""
        
        # Validation
        xcrun altool --validate-app \
            -f "$IPA_PATH/Runner.ipa" \
            -t ios \
            -u "$APPLE_ID" \
            -p "$APP_PASSWORD"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Validation réussie${NC}"
            echo ""
            
            echo -e "${YELLOW}📤 Upload vers App Store Connect...${NC}"
            xcrun altool --upload-app \
                -f "$IPA_PATH/Runner.ipa" \
                -t ios \
                -u "$APPLE_ID" \
                -p "$APP_PASSWORD"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Upload réussi !${NC}"
            else
                echo -e "${RED}❌ Erreur lors de l'upload${NC}"
            fi
        else
            echo -e "${RED}❌ Erreur lors de la validation${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  altool non disponible. Utilisez Transporter ou Xcode Organizer${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Upload ignoré${NC}"
fi

echo ""

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║              ✅  BUILD TERMINÉ AVEC SUCCÈS  ✅             ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}📊 RÉSUMÉ:${NC}"
echo -e "${CYAN}   • Application: $APP_NAME${NC}"
echo -e "${CYAN}   • Bundle ID: $BUNDLE_ID${NC}"
echo -e "${CYAN}   • Version: $VERSION_NUMBER${NC}"
echo -e "${CYAN}   • Build: $BUILD_NUMBER${NC}"
echo -e "${CYAN}   • Archive: $ARCHIVE_PATH${NC}"
echo -e "${CYAN}   • IPA: $IPA_PATH/Runner.ipa${NC}"
echo -e "${CYAN}   • Taille: $IPA_SIZE${NC}"
echo ""
echo -e "${BOLD}📝 PROCHAINES ÉTAPES:${NC}"
echo ""
echo -e "${YELLOW}1.${NC} Si vous n'avez pas uploadé, vous pouvez le faire via:"
echo -e "   ${CYAN}• Transporter app (recommandé)${NC}"
echo -e "   ${CYAN}• Xcode > Window > Organizer${NC}"
echo ""
echo -e "${YELLOW}2.${NC} Connectez-vous à App Store Connect:"
echo -e "   ${CYAN}https://appstoreconnect.apple.com${NC}"
echo ""
echo -e "${YELLOW}3.${NC} Une fois l'upload terminé (traitement ~10-30 min):"
echo -e "   ${CYAN}• Allez dans 'Mes Apps' > '$APP_NAME'${NC}"
echo -e "   ${CYAN}• Sélectionnez la version dans 'App Store'${NC}"
echo -e "   ${CYAN}• Ajoutez les captures d'écran (obligatoire)${NC}"
echo -e "   ${CYAN}• Remplissez la description et les infos${NC}"
echo -e "   ${CYAN}• Sélectionnez le build uploadé${NC}"
echo -e "   ${CYAN}• Soumettez pour review${NC}"
echo ""
echo -e "${BOLD}${CYAN}📱 IMPORTANT - Captures d'écran requises:${NC}"
echo -e "   • iPhone 6.7\" (Pro Max): 1290x2796 px"
echo -e "   • iPhone 6.5\" (Plus): 1242x2688 px"
echo -e "   • iPhone 5.5\": 1242x2208 px"
echo -e "   • iPad Pro 12.9\": 2048x2732 px"
echo ""
echo -e "${BOLD}${GREEN}🎉 Bonne chance avec votre soumission App Store ! 🎉${NC}"
echo ""
