#!/bin/bash

# Script de génération automatique de captures d'écran
# pour Jubilé Tabernacle - App Store et Play Store

echo "🚀 Génération des captures d'écran Jubilé Tabernacle"

# Configuration
APP_NAME="Jubilé Tabernacle"
OUTPUT_DIR="screenshots"
DATE=$(date +%Y-%m-%d)

# Créer le dossier de sortie
mkdir -p $OUTPUT_DIR/{ios/{iphone,ipad},android/{phone,tablet}}

echo "📁 Dossiers créés dans $OUTPUT_DIR"

# Fonction pour iPhone captures
generate_iphone_screenshots() {
    echo "📱 Génération captures iPhone..."
    
    # iPhone 6.7" (Pro Max)
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="iPhone 15 Pro Max" \
        --screenshot=$OUTPUT_DIR/ios/iphone/
    
    # iPhone 6.5" (Standard)
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="iPhone 15" \
        --screenshot=$OUTPUT_DIR/ios/iphone/
}

# Fonction pour iPad captures  
generate_ipad_screenshots() {
    echo "📱 Génération captures iPad..."
    
    # iPad Pro 12.9"
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="iPad Pro (12.9-inch)" \
        --screenshot=$OUTPUT_DIR/ios/ipad/
    
    # iPad Pro 11"
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="iPad Pro (11-inch)" \
        --screenshot=$OUTPUT_DIR/ios/ipad/
}

# Fonction pour Android captures
generate_android_screenshots() {
    echo "📱 Génération captures Android..."
    
    # Phone
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="emulator-5554" \
        --screenshot=$OUTPUT_DIR/android/phone/
    
    # Tablet  
    flutter drive \
        --driver=test_driver/screenshot_test.dart \
        --target=test_driver/app.dart \
        --device-id="emulator-5556" \
        --screenshot=$OUTPUT_DIR/android/tablet/
}

# Fonction de post-traitement
process_screenshots() {
    echo "🎨 Traitement des captures..."
    
    # Redimensionner et optimiser
    for file in $OUTPUT_DIR/**/*.png; do
        echo "Traitement de $file"
        
        # Optimiser la taille
        pngquant --quality=80-95 --ext .png --force "$file"
        
        # Ajouter métadonnées
        exiftool -overwrite_original \
            -Artist="Jubilé Tabernacle" \
            -Copyright="© 2025 Jubilé Tabernacle" \
            -Description="Capture d'écran de l'application $APP_NAME" \
            "$file"
    done
}

# Fonction principale
main() {
    echo "🔥 Démarrage de la génération..."
    
    # Vérifier que Flutter est installé
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter n'est pas installé"
        exit 1
    fi
    
    # Nettoyer les anciens fichiers
    echo "🧹 Nettoyage des anciens fichiers..."
    rm -rf $OUTPUT_DIR
    
    # Générer selon la plateforme
    case "${1:-all}" in
        "ios")
            generate_iphone_screenshots
            generate_ipad_screenshots
            ;;
        "android")  
            generate_android_screenshots
            ;;
        "all"|*)
            generate_iphone_screenshots
            generate_ipad_screenshots  
            generate_android_screenshots
            ;;
    esac
    
    # Post-traitement
    process_screenshots
    
    echo "✅ Captures générées dans $OUTPUT_DIR"
    echo "📊 Statistiques:"
    find $OUTPUT_DIR -name "*.png" | wc -l | xargs echo "   Total images:"
    du -sh $OUTPUT_DIR | awk '{print "   Taille totale: " $1}'
}

# Aide
show_help() {
    echo "Usage: $0 [ios|android|all]"
    echo ""
    echo "Options:"
    echo "  ios      Générer uniquement les captures iOS"
    echo "  android  Générer uniquement les captures Android" 
    echo "  all      Générer toutes les captures (défaut)"
    echo ""
    echo "Exemples:"
    echo "  $0           # Génère toutes les captures"
    echo "  $0 ios       # Génère uniquement iOS"
    echo "  $0 android   # Génère uniquement Android"
}

# Gestion des arguments
case "${1}" in
    "-h"|"--help")
        show_help
        exit 0
        ;;
    *)
        main "$1"
        ;;
esac
