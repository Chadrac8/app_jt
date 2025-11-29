#!/bin/bash

# ============================================================================
# 📸 SCRIPT DE CAPTURE D'ÉCRAN POUR APP STORE
# ============================================================================
# Ce script aide à prendre des captures d'écran dans les bonnes dimensions
# pour l'App Store
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║        📸  CAPTURES D'ÉCRAN APP STORE  📸                 ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Créer le dossier de screenshots
SCREENSHOTS_DIR="screenshots_app_store"
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${GREEN}✅ Dossier créé: $SCREENSHOTS_DIR${NC}"
echo ""

echo -e "${BOLD}📱 APPAREILS REQUIS:${NC}"
echo ""
echo -e "${YELLOW}1. iPhone 15 Pro Max (6.7\")${NC}"
echo -e "   Résolution: 1290 x 2796 px"
echo -e "   ${CYAN}flutter run -d 'iPhone 15 Pro Max'${NC}"
echo ""
echo -e "${YELLOW}2. iPhone 15 Plus (6.5\")${NC}"
echo -e "   Résolution: 1242 x 2688 px"
echo -e "   ${CYAN}flutter run -d 'iPhone 15 Plus'${NC}"
echo ""
echo -e "${YELLOW}3. iPhone 8 Plus (5.5\")${NC}"
echo -e "   Résolution: 1242 x 2208 px"
echo -e "   ${CYAN}flutter run -d 'iPhone 8 Plus'${NC}"
echo ""
echo -e "${YELLOW}4. iPad Pro 12.9\" (optionnel)${NC}"
echo -e "   Résolution: 2048 x 2732 px"
echo -e "   ${CYAN}flutter run -d 'iPad Pro (12.9-inch)'${NC}"
echo ""

echo -e "${BOLD}🎯 CAPTURES À FAIRE (minimum 3, recommandé 5-8):${NC}"
echo ""
echo "1. 🏠 Écran d'accueil - Pain quotidien"
echo "2. 📖 Module Bible avec versets"
echo "3. ⛪ Vie de l'église (sermons/événements)"
echo "4. 🙏 Prières communautaires"
echo "5. 👤 Profil utilisateur"
echo "6. 💰 Module Offrandes (optionnel)"
echo "7. 🌙 Mode sombre (optionnel)"
echo "8. 🔍 Recherche Bible (optionnel)"
echo ""

echo -e "${BOLD}📋 INSTRUCTIONS:${NC}"
echo ""
echo "1. Lancer l'app sur le simulateur:"
echo -e "   ${CYAN}flutter run${NC}"
echo ""
echo "2. Sélectionner le device dans le simulateur:"
echo -e "   ${CYAN}Device > iPhone 15 Pro Max${NC}"
echo ""
echo "3. Naviguer vers l'écran à capturer"
echo ""
echo "4. Prendre la capture:"
echo -e "   ${CYAN}Cmd + S${NC} (sauvegardée sur le Bureau)"
echo "   ou"
echo -e "   ${CYAN}xcrun simctl io booted screenshot <fichier.png>${NC}"
echo ""
echo "5. Répéter pour tous les devices requis"
echo ""
echo "6. Organiser les captures dans des sous-dossiers:"
echo "   $SCREENSHOTS_DIR/6.7_inch/"
echo "   $SCREENSHOTS_DIR/6.5_inch/"
echo "   $SCREENSHOTS_DIR/5.5_inch/"
echo "   $SCREENSHOTS_DIR/12.9_inch/"
echo ""

# Créer les sous-dossiers
mkdir -p "$SCREENSHOTS_DIR/6.7_inch"
mkdir -p "$SCREENSHOTS_DIR/6.5_inch"
mkdir -p "$SCREENSHOTS_DIR/5.5_inch"
mkdir -p "$SCREENSHOTS_DIR/12.9_inch"

echo -e "${GREEN}✅ Sous-dossiers créés${NC}"
echo ""

echo -e "${BOLD}💡 ASTUCES:${NC}"
echo ""
echo "• Utilisez un simulateur propre (sans notifications)"
echo "• Captures en mode portrait uniquement"
echo "• Évitez les données personnelles dans les captures"
echo "• Utilisez des contenus représentatifs"
echo "• Assurez-vous que le texte est lisible"
echo "• Testez le mode sombre pour variété"
echo ""

echo -e "${BOLD}🎨 OUTILS POUR EMBELLIR (optionnel):${NC}"
echo ""
echo "• Figma / Sketch - Ajouter des cadres device"
echo "• Screenshots.pro - Générateur de cadres"
echo "• AppMockUp - Maquettes professionnelles"
echo ""

echo -e "${BOLD}✅ VALIDATION DES DIMENSIONS:${NC}"
echo ""
echo "Après avoir pris vos captures, validez les dimensions:"
echo ""
echo -e "${CYAN}sips -g pixelWidth -g pixelHeight screenshots_app_store/6.7_inch/*.png${NC}"
echo ""

echo -e "${GREEN}📁 Dossier prêt: $SCREENSHOTS_DIR/${NC}"
echo ""
echo -e "${BOLD}🚀 Une fois les captures prêtes:${NC}"
echo "   Uploadez-les dans App Store Connect > Mes Apps > Jubilé Tabernacle"
echo "   Section: App Store > Captures d'écran"
echo ""
