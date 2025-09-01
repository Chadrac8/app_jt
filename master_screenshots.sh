#!/bin/bash

# SCRIPT MAÎTRE - Génération complète des captures d'écran
# Jubilé Tabernacle - App Store et Play Store

set -e

echo "🚀 GÉNÉRATION COMPLÈTE DES CAPTURES D'ÉCRAN"
echo "============================================"
echo "Application: Jubilé Tabernacle"
echo "Date: $(date)"
echo ""

# Configuration
RAW_DIR="captures_raw"
FINAL_DIR="captures_final" 
MARKETING_DIR="captures_marketing"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
print_step() {
    echo -e "${BLUE}📋 ÉTAPE $1: $2${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérification des prérequis
check_requirements() {
    print_step "1" "Vérification des prérequis"
    
    local missing_tools=()
    
    if ! command -v flutter &> /dev/null; then
        missing_tools+=("Flutter")
    fi
    
    if ! command -v convert &> /dev/null; then
        missing_tools+=("ImageMagick")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Outils manquants: ${missing_tools[*]}"
        echo "Installez les outils requis:"
        echo "  Flutter: https://flutter.dev/docs/get-started/install"
        echo "  ImageMagick: brew install imagemagick"
        exit 1
    fi
    
    print_success "Tous les outils sont installés"
}

# Vérification de l'application
check_app() {
    print_step "2" "Vérification de l'application"
    
    if [ ! -f "pubspec.yaml" ]; then
        print_error "Pas de projet Flutter détecté (pubspec.yaml manquant)"
        exit 1
    fi
    
    # Vérifier que l'app compile
    print_warning "Compilation de l'application en cours..."
    if flutter analyze --no-fatal-infos --no-fatal-warnings > /dev/null 2>&1; then
        print_success "Application compilée avec succès"
    else
        print_warning "Attention: des warnings détectés dans l'application"
        echo "Continuez-vous quand même? [y/N]"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Préparation des dossiers
setup_directories() {
    print_step "3" "Préparation des dossiers"
    
    # Nettoyer les anciens fichiers
    rm -rf "$FINAL_DIR" "$MARKETING_DIR"
    
    # Créer le dossier raw s'il n'existe pas
    if [ ! -d "$RAW_DIR" ]; then
        mkdir -p "$RAW_DIR"
        print_warning "Dossier '$RAW_DIR' créé"
        echo ""
        echo "📸 ACTIONS REQUISES:"
        echo "=================="
        echo "1. Lancez votre application Flutter:"
        echo "   flutter run"
        echo ""
        echo "2. Prenez 6-8 captures d'écran manuellement:"
        echo "   • 01_accueil_principal.png"
        echo "   • 02_bible_message.png"
        echo "   • 03_vie_eglise.png"
        echo "   • 04_pain_quotidien.png"
        echo "   • 05_prieres_optimise.png"
        echo "   • 06_pour_vous.png"
        echo ""
        echo "3. Placez les captures dans le dossier '$RAW_DIR'"
        echo ""
        echo "4. Relancez ce script: ./master_screenshots.sh"
        echo ""
        exit 0
    fi
    
    # Vérifier que des captures existent
    local capture_count=$(find "$RAW_DIR" -name "*.png" | wc -l | tr -d ' ')
    if [ "$capture_count" -eq 0 ]; then
        print_error "Aucune capture trouvée dans '$RAW_DIR'"
        echo "Prenez vos captures d'écran et placez-les dans ce dossier"
        exit 1
    fi
    
    print_success "$capture_count captures trouvées dans '$RAW_DIR'"
}

# Redimensionnement automatique
resize_screenshots() {
    print_step "4" "Redimensionnement pour tous les formats"
    
    if [ ! -f "resize_screenshots.sh" ]; then
        print_error "Script resize_screenshots.sh manquant"
        exit 1
    fi
    
    ./resize_screenshots.sh "$RAW_DIR" "$FINAL_DIR"
    
    local final_count=$(find "$FINAL_DIR" -name "*.png" | wc -l | tr -d ' ')
    print_success "$final_count images redimensionnées générées"
}

# Ajout de texte marketing
add_marketing() {
    print_step "5" "Ajout de texte marketing"
    
    echo "Voulez-vous ajouter du texte marketing aux captures? [y/N]"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if [ ! -f "add_marketing_text.sh" ]; then
            print_error "Script add_marketing_text.sh manquant"
            exit 1
        fi
        
        ./add_marketing_text.sh "$FINAL_DIR" "$MARKETING_DIR"
        
        local marketing_count=$(find "$MARKETING_DIR" -name "*.png" | wc -l | tr -d ' ')
        print_success "$marketing_count images avec texte marketing générées"
    else
        print_warning "Texte marketing ignoré"
    fi
}

# Génération du rapport final
generate_report() {
    print_step "6" "Génération du rapport final"
    
    local report_file="rapport_screenshots_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
📱 RAPPORT GÉNÉRATION CAPTURES D'ÉCRAN
=====================================

Application: Jubilé Tabernacle
Date: $(date)
Générateur: Script automatique v1.0

📊 STATISTIQUES:
===============

Captures source: $(find "$RAW_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
Images finales: $(find "$FINAL_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
Images marketing: $([ -d "$MARKETING_DIR" ] && find "$MARKETING_DIR" -name "*.png" | wc -l | tr -d ' ' || echo "0")

📂 STRUCTURE GÉNÉRÉE:
====================

EOF

    # Ajouter détails par format
    if [ -d "$FINAL_DIR" ]; then
        for format_dir in "$FINAL_DIR"/*/; do
            if [ -d "$format_dir" ]; then
                format_name=$(basename "$format_dir")
                count=$(find "$format_dir" -name "*.png" | wc -l | tr -d ' ')
                size=$(du -sh "$format_dir" 2>/dev/null | cut -f1 || echo "0B")
                echo "$format_name: $count images ($size)" >> "$report_file"
            fi
        done
    fi

    cat >> "$report_file" << EOF

🎯 FORMATS SUPPORTÉS:
====================

iOS App Store:
✅ iPhone 6.7" (1290x2796) - iPhone 15 Pro Max
✅ iPhone 6.5" (1242x2688) - iPhone 15
✅ iPad 12.9" (2048x2732) - iPad Pro
✅ iPad 11" (1668x2388) - iPad Pro

Android Play Store:
✅ Phone (1080x1920) - Standard
✅ Tablet (1200x1920) - Tablette 7-10"

📋 PROCHAINES ÉTAPES:
====================

1. 🔍 Vérifiez la qualité des captures générées
2. 📱 Testez l'affichage sur différents appareils
3. 🏪 Upload sur App Store Connect (iOS)
4. 🏪 Upload sur Google Play Console (Android)
5. 📊 Analysez les performances après publication

🛠️ FICHIERS GÉNÉRÉS:
====================

• $FINAL_DIR/ - Images redimensionnées pour stores
• $MARKETING_DIR/ - Images avec texte marketing (si générées)
• apercu.html - Aperçu web de toutes les captures
• $report_file - Ce rapport

✨ APPLICATION PRÊTE POUR PUBLICATION !
EOF

    print_success "Rapport généré: $report_file"
}

# Affichage du résumé final
show_summary() {
    echo ""
    echo "🎉 GÉNÉRATION TERMINÉE AVEC SUCCÈS !"
    echo "===================================="
    echo ""
    
    if [ -d "$FINAL_DIR" ]; then
        local total_final=$(find "$FINAL_DIR" -name "*.png" | wc -l | tr -d ' ')
        local size_final=$(du -sh "$FINAL_DIR" 2>/dev/null | cut -f1 || echo "0B")
        echo "📱 Images pour stores: $total_final ($size_final)"
    fi
    
    if [ -d "$MARKETING_DIR" ]; then
        local total_marketing=$(find "$MARKETING_DIR" -name "*.png" | wc -l | tr -d ' ')
        local size_marketing=$(du -sh "$MARKETING_DIR" 2>/dev/null | cut -f1 || echo "0B")
        echo "🎨 Images marketing: $total_marketing ($size_marketing)"
    fi
    
    echo ""
    echo "📂 Fichiers dans:"
    [ -d "$FINAL_DIR" ] && echo "   • $FINAL_DIR/ (pour stores)"
    [ -d "$MARKETING_DIR" ] && echo "   • $MARKETING_DIR/ (marketing)"
    [ -f "$MARKETING_DIR/apercu.html" ] && echo "   • $MARKETING_DIR/apercu.html (aperçu web)"
    
    echo ""
    echo "🚀 Votre application Jubilé Tabernacle est prête pour publication !"
    
    if [ -f "$MARKETING_DIR/apercu.html" ]; then
        echo ""
        echo "💡 Ouvrez l'aperçu web:"
        echo "   open $MARKETING_DIR/apercu.html"
    fi
}

# Fonction principale
main() {
    echo "🔥 Démarrage de la génération automatique..."
    echo ""
    
    check_requirements
    check_app
    setup_directories
    resize_screenshots
    add_marketing
    generate_report
    show_summary
    
    echo ""
    print_success "🏁 Processus terminé avec succès !"
}

# Gestion des arguments
case "${1}" in
    "-h"|"--help")
        echo "Usage: $0"
        echo ""
        echo "Ce script automatise la génération complète des captures d'écran"
        echo "pour l'App Store et le Play Store."
        echo ""
        echo "Prérequis:"
        echo "  - Flutter installé"
        echo "  - ImageMagick installé (brew install imagemagick)"
        echo "  - Captures d'écran dans le dossier captures_raw/"
        echo ""
        echo "Le script génère:"
        echo "  - Images redimensionnées pour tous les formats"
        echo "  - Versions avec texte marketing (optionnel)"
        echo "  - Aperçu HTML de toutes les captures"
        echo "  - Rapport détaillé de génération"
        ;;
    *)
        main
        ;;
esac
