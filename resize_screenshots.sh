#!/bin/bash

# Script de redimensionnement automatique des captures d'écran
# pour App Store et Play Store - Jubilé Tabernacle

set -e  # Arrêter en cas d'erreur

echo "🎨 Redimensionnement automatique des captures d'écran"

# Configuration
INPUT_DIR="${1:-captures_raw}"
OUTPUT_DIR="${2:-captures_final}"
QUALITY=90

# Vérifier que ImageMagick est installé
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick n'est pas installé"
    echo "Installez-le avec: brew install imagemagick"
    exit 1
fi

# Créer la structure de dossiers
echo "📁 Création de la structure de dossiers..."
mkdir -p "$OUTPUT_DIR"/{ios/{iphone_67,iphone_65,ipad_129,ipad_11},android/{phone,tablet}}

# Définir les tailles cibles
declare -A SIZES=(
    ["ios/iphone_67"]="1290x2796"
    ["ios/iphone_65"]="1242x2688"
    ["ios/ipad_129"]="2048x2732"
    ["ios/ipad_11"]="1668x2388"
    ["android/phone"]="1080x1920"
    ["android/tablet"]="1200x1920"
)

# Fonction de redimensionnement avec optimisation
resize_image() {
    local input="$1"
    local output="$2"
    local size="$3"
    local filename=$(basename "$input" .png)
    
    echo "   📱 $size - $filename"
    
    convert "$input" \
        -resize "$size^" \
        -gravity center \
        -extent "$size" \
        -quality $QUALITY \
        -strip \
        -colorspace sRGB \
        "$output"
}

# Fonction d'ajout de métadonnées
add_metadata() {
    local file="$1"
    
    if command -v exiftool &> /dev/null; then
        exiftool -overwrite_original \
            -Artist="Jubilé Tabernacle" \
            -Copyright="© 2025 Jubilé Tabernacle" \
            -Description="Capture d'écran de l'application Jubilé Tabernacle" \
            -Software="Flutter/Dart" \
            "$file" 2>/dev/null || true
    fi
}

# Vérifier que le dossier d'entrée existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Dossier d'entrée '$INPUT_DIR' non trouvé"
    echo "Créez le dossier et placez-y vos captures d'écran PNG"
    exit 1
fi

# Compter les images d'entrée
image_count=$(find "$INPUT_DIR" -name "*.png" | wc -l | tr -d ' ')
if [ "$image_count" -eq 0 ]; then
    echo "❌ Aucune image PNG trouvée dans '$INPUT_DIR'"
    exit 1
fi

echo "📊 $image_count images trouvées dans '$INPUT_DIR'"

# Traiter chaque image pour chaque format
total_operations=$((image_count * ${#SIZES[@]}))
current_operation=0

for image in "$INPUT_DIR"/*.png; do
    if [ ! -f "$image" ]; then continue; fi
    
    filename=$(basename "$image" .png)
    echo "🖼️  Traitement de $filename..."
    
    for format in "${!SIZES[@]}"; do
        size="${SIZES[$format]}"
        output_file="$OUTPUT_DIR/$format/${filename}_${size}.png"
        
        resize_image "$image" "$output_file" "$size"
        add_metadata "$output_file"
        
        current_operation=$((current_operation + 1))
        progress=$((current_operation * 100 / total_operations))
        echo "📈 Progression: $progress% ($current_operation/$total_operations)"
    done
done

# Statistiques finales
echo ""
echo "✅ Redimensionnement terminé !"
echo "📊 Statistiques :"

total_size=0
for format in "${!SIZES[@]}"; do
    count=$(find "$OUTPUT_DIR/$format" -name "*.png" | wc -l | tr -d ' ')
    size=$(du -sh "$OUTPUT_DIR/$format" 2>/dev/null | cut -f1 || echo "0B")
    echo "   $format: $count images ($size)"
done

total_final=$(find "$OUTPUT_DIR" -name "*.png" | wc -l | tr -d ' ')
total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "0B")
echo "   📱 Total: $total_final images ($total_size)"

echo ""
echo "📂 Fichiers générés dans: $OUTPUT_DIR"
echo "🚀 Prêt pour upload sur App Store et Play Store !"

# Générer un rapport détaillé
cat > "$OUTPUT_DIR/rapport_generation.txt" << EOF
RAPPORT DE GÉNÉRATION DES CAPTURES D'ÉCRAN
==========================================

Application: Jubilé Tabernacle
Date: $(date)
Images source: $image_count
Images générées: $total_final
Taille totale: $total_size

FORMATS GÉNÉRÉS:
================

iOS App Store:
- iPhone 6.7" (Pro Max): ${SIZES["ios/iphone_67"]} px
- iPhone 6.5" (Standard): ${SIZES["ios/iphone_65"]} px  
- iPad 12.9" (Pro): ${SIZES["ios/ipad_129"]} px
- iPad 11" (Pro): ${SIZES["ios/ipad_11"]} px

Android Play Store:
- Phone: ${SIZES["android/phone"]} px
- Tablet: ${SIZES["android/tablet"]} px

QUALITÉ: $QUALITY%
MÉTADONNÉES: Ajoutées
COLORSPACE: sRGB
FORMAT: PNG optimisé

PROCHAINES ÉTAPES:
==================
1. Vérifier la qualité des images générées
2. Upload sur App Store Connect (iOS)
3. Upload sur Google Play Console (Android)
4. Tester l'affichage sur différents appareils

EOF

echo "📄 Rapport généré: $OUTPUT_DIR/rapport_generation.txt"
