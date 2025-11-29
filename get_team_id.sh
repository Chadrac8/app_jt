#!/bin/bash

# ============================================================================
# 🔍 OBTENIR VOTRE TEAM ID APPLE DEVELOPER
# ============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}🔍 COMMENT OBTENIR VOTRE TEAM ID APPLE DEVELOPER${NC}"
echo ""

echo -e "${BOLD}Méthode 1: Via le Site Apple Developer (Recommandé)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Ouvrez votre navigateur"
echo "2. Allez sur: ${CYAN}https://developer.apple.com${NC}"
echo "3. Connectez-vous avec votre Apple ID"
echo "4. Cliquez sur 'Account' (en haut à droite)"
echo "5. Allez dans 'Membership'"
echo "6. Votre Team ID est affiché:"
echo "   ${GREEN}Team ID: ABC1234567${NC} (10 caractères)"
echo ""

echo -e "${BOLD}Méthode 2: Via Xcode${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Ouvrez Xcode"
echo "2. Xcode > Preferences > Accounts"
echo "3. Sélectionnez votre Apple ID"
echo "4. Cliquez sur votre équipe"
echo "5. Le Team ID est affiché à droite"
echo ""

echo -e "${BOLD}Méthode 3: Via Terminal (si connecté)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Exécutez cette commande:"
echo -e "${CYAN}security find-certificate -a -c 'Apple Development' | grep 'alis' | head -1${NC}"
echo ""

echo -e "${BOLD}Format du Team ID:${NC}"
echo "  • 10 caractères alphanumériques"
echo "  • Exemple: ${GREEN}A1B2C3D4E5${NC}"
echo "  • Pas d'espaces ni caractères spéciaux"
echo ""

echo -e "${BOLD}Une fois obtenu, configurez-le dans le script:${NC}"
echo ""
echo -e "${YELLOW}1. Ouvrez le fichier:${NC}"
echo "   ${CYAN}nano deploy_app_store.sh${NC}"
echo ""
echo -e "${YELLOW}2. Recherchez (Ctrl+W):${NC}"
echo "   ${CYAN}VOTRE_TEAM_ID${NC}"
echo ""
echo -e "${YELLOW}3. Remplacez par votre Team ID:${NC}"
echo "   Avant:  ${CYAN}DEVELOPMENT_TEAM=\"VOTRE_TEAM_ID\"${NC}"
echo "   Après:  ${GREEN}DEVELOPMENT_TEAM=\"A1B2C3D4E5\"${NC}"
echo ""
echo -e "${YELLOW}4. Sauvegardez:${NC}"
echo "   Ctrl+O (Enter) puis Ctrl+X"
echo ""

echo -e "${BOLD}${GREEN}✅ Vous êtes prêt à builder !${NC}"
echo ""
echo "Ensuite, lancez:"
echo "  ${CYAN}./deploy_app_store.sh${NC}"
echo ""
