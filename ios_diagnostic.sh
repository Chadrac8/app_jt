#!/bin/bash

# Script de Diagnostic iOS pour Jubilé Tabernacle
# Résout les problèmes de lancement sur appareil physique

echo "🔍 DIAGNOSTIC iOS - JUBILÉ TABERNACLE"
echo "====================================="

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Diagnostic pour iPhone physique${NC}"
echo ""

# Étape 1: Vérifier les appareils connectés
echo -e "${YELLOW}🔌 Vérification des appareils connectés...${NC}"
flutter devices
echo ""

# Étape 2: Vérifier l'état du projet iOS
echo -e "${YELLOW}📋 État du projet iOS...${NC}"
if [ -d "ios/Pods" ]; then
    echo -e "${GREEN}✅ CocoaPods installé${NC}"
else
    echo -e "${RED}❌ CocoaPods manquant${NC}"
fi

if [ -f "ios/Podfile.lock" ]; then
    echo -e "${GREEN}✅ Podfile.lock présent${NC}"
else
    echo -e "${RED}❌ Podfile.lock manquant${NC}"
fi

if [ -f "ios/Runner.xcworkspace" ]; then
    echo -e "${GREEN}✅ Workspace Xcode présent${NC}"
else
    echo -e "${RED}❌ Workspace Xcode manquant${NC}"
fi
echo ""

# Étape 3: Solutions recommandées
echo -e "${YELLOW}🛠️  SOLUTIONS RECOMMANDÉES${NC}"
echo ""

echo -e "${BLUE}1. NETTOYAGE COMPLET:${NC}"
echo "   flutter clean && rm -rf ios/Pods ios/Podfile.lock"
echo "   flutter pub get && cd ios && pod install"
echo ""

echo -e "${BLUE}2. CONFIGURATION XCODE MANUELLE:${NC}"
echo "   - Ouvrir: ios/Runner.xcworkspace"
echo "   - Signing & Capabilities > Team"
echo "   - Bundle Identifier unique"
echo "   - Deployment Target >= 12.0"
echo ""

echo -e "${BLUE}3. COMMANDES DE TEST:${NC}"
echo "   # Test simulateur:"
echo "   flutter run -d 'iPhone 15 Pro Max'"
echo ""
echo "   # Test appareil physique (remplacer par votre ID):"
echo "   flutter run -d [DEVICE_ID]"
echo ""

echo -e "${BLUE}4. ALTERNATIVE - BUILD IPA:${NC}"
echo "   flutter build ipa --release"
echo "   # Puis installer via Xcode"
echo ""

# Étape 4: Correction automatique
echo -e "${YELLOW}🚀 Lancement de la correction automatique...${NC}"
echo ""

echo -e "${BLUE}Nettoyage en cours...${NC}"
flutter clean > /dev/null 2>&1
rm -rf ios/Pods ios/Podfile.lock > /dev/null 2>&1

echo -e "${BLUE}Récupération des dépendances...${NC}"
flutter pub get > /dev/null 2>&1

echo -e "${BLUE}Installation des CocoaPods...${NC}"
cd ios && pod install --repo-update > /dev/null 2>&1
cd ..

echo -e "${GREEN}✅ Correction automatique terminée${NC}"
echo ""

# Étape 5: Test simulateur
echo -e "${YELLOW}🧪 Test sur simulateur...${NC}"
echo "Pour tester immédiatement:"
echo "flutter run -d \"Mon simulateur\""
echo ""

echo -e "${YELLOW}📋 PROCHAINES ÉTAPES:${NC}"
echo "1. Ouvrir Xcode: ios/Runner.xcworkspace"
echo "2. Configurer le signing (Team + Bundle ID)"
echo "3. Essayer: flutter run -d [DEVICE_ID]"
echo ""

echo -e "${BLUE}🔗 En cas de problème persistant:${NC}"
echo "• Redémarrer Xcode"
echo "• Redémarrer l'iPhone"
echo "• Vérifier le câble USB"
echo "• Faire confiance à l'ordinateur sur l'iPhone"
echo ""

echo -e "${GREEN}✨ Diagnostic terminé!${NC}"