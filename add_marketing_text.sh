#!/bin/bash

# Script d'ajout de texte marketing aux captures d'écran
# Jubilé Tabernacle - App Store et Play Store

set -e

echo "🎨 Ajout de texte marketing aux captures d'écran"

# Configuration
INPUT_DIR="${1:-captures_final}"
OUTPUT_DIR="${2:-captures_marketing}"
FONT_SIZE_TITLE=48
FONT_SIZE_DESC=28
COLOR_TITLE="#6B73FF"
COLOR_DESC="#2D3748"
MARGIN_TOP=60
MARGIN_DESC=140

# Vérifier ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick requis: brew install imagemagick"
    exit 1
fi

# Créer dossier de sortie
mkdir -p "$OUTPUT_DIR"

# Définir les textes marketing
declare -A MARKETING_TEXTS=(
    ["01_accueil"]="Jubilé Tabernacle|Votre compagnon spirituel quotidien"
    ["02_bible"]="Bible Interactive|Étudiez la Parole avec des outils modernes"
    ["03_vie_eglise"]="Vie de l'Église|Connectez-vous avec votre communauté"
    ["04_pain_quotidien"]="Pain Quotidien|Inspiration spirituelle chaque jour"
    ["05_prieres"]="Prières & Témoignages|Interface optimisée, plus d'espace"
    ["06_pour_vous"]="Pour Vous|Fonctionnalités personnalisées"
    ["07_configuration"]="Configuration|Personnalisez votre expérience"
    ["08_profil"]="Profil|Gérez votre compte facilement"
)

# Fonction d'ajout de texte
add_marketing_text() {
    local input="$1"
    local title="$2"
    local description="$3"
    local output="$4"
    
    # Obtenir les dimensions de l'image
    local width=$(identify -format "%w" "$input")
    local height=$(identify -format "%h" "$input")
    
    # Ajuster la taille de police selon la largeur
    local title_size=$FONT_SIZE_TITLE
    local desc_size=$FONT_SIZE_DESC
    
    if [ "$width" -gt 1500 ]; then
        title_size=64
        desc_size=36
    elif [ "$width" -lt 1100 ]; then
        title_size=36
        desc_size=20
    fi
    
    echo "   📝 $title ($width x $height)"
    
    # Créer l'image avec texte
    convert "$input" \
        -gravity North \
        -pointsize $title_size \
        -fill "$COLOR_TITLE" \
        -font "Arial-Bold" \
        -annotate +0+$MARGIN_TOP "$title" \
        -pointsize $desc_size \
        -fill "$COLOR_DESC" \
        -font "Arial" \
        -annotate +0+$MARGIN_DESC "$description" \
        -quality 95 \
        "$output"
}

# Fonction de traitement par lots
process_directory() {
    local dir="$1"
    local subdir=$(basename "$dir")
    
    echo "📁 Traitement du dossier: $subdir"
    
    mkdir -p "$OUTPUT_DIR/$subdir"
    
    for image in "$dir"/*.png; do
        if [ ! -f "$image" ]; then continue; fi
        
        local filename=$(basename "$image" .png)
        local base_name=$(echo "$filename" | sed 's/_[0-9]*x[0-9]*$//')
        
        # Trouver le texte marketing correspondant
        local marketing_key=""
        for key in "${!MARKETING_TEXTS[@]}"; do
            if [[ "$base_name" == *"$key"* ]]; then
                marketing_key="$key"
                break
            fi
        done
        
        if [ -n "$marketing_key" ]; then
            local marketing_text="${MARKETING_TEXTS[$marketing_key]}"
            local title=$(echo "$marketing_text" | cut -d'|' -f1)
            local description=$(echo "$marketing_text" | cut -d'|' -f2)
            
            local output_file="$OUTPUT_DIR/$subdir/$filename"
            add_marketing_text "$image" "$title" "$description" "$output_file"
        else
            echo "   ⚠️  Aucun texte marketing trouvé pour $base_name"
            cp "$image" "$OUTPUT_DIR/$subdir/"
        fi
    done
}

# Vérifier le dossier d'entrée
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Dossier '$INPUT_DIR' non trouvé"
    echo "Exécutez d'abord: ./resize_screenshots.sh"
    exit 1
fi

# Traiter tous les sous-dossiers
echo "🚀 Démarrage du traitement..."

for subdir in "$INPUT_DIR"/*/; do
    if [ -d "$subdir" ]; then
        process_directory "$subdir"
    fi
done

# Créer des versions sans texte pour les stores qui le préfèrent
echo "📱 Création de versions sans texte..."
mkdir -p "$OUTPUT_DIR/clean"
find "$INPUT_DIR" -name "*.png" -exec cp {} "$OUTPUT_DIR/clean/" \;

# Statistiques finales
total_marketing=$(find "$OUTPUT_DIR" -name "*.png" -not -path "*/clean/*" | wc -l | tr -d ' ')
total_clean=$(find "$OUTPUT_DIR/clean" -name "*.png" | wc -l | tr -d ' ')
total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "0B")

echo ""
echo "✅ Traitement terminé !"
echo "📊 Résultats :"
echo "   🎨 Avec texte marketing: $total_marketing images"
echo "   🧹 Versions propres: $total_clean images"
echo "   📦 Taille totale: $total_size"
echo ""
echo "📂 Fichiers dans: $OUTPUT_DIR"

# Générer aperçu HTML
cat > "$OUTPUT_DIR/apercu.html" << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aperçu Captures - Jubilé Tabernacle</title>
    <style>
        body { font-family: -apple-system, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .section { margin-bottom: 40px; background: white; padding: 20px; border-radius: 10px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .image-card { text-align: center; }
        .image-card img { max-width: 100%; height: auto; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .image-card h4 { margin: 10px 0 5px; color: #6B73FF; }
        .image-card p { margin: 0; color: #666; font-size: 14px; }
        h1 { color: #6B73FF; text-align: center; }
        h2 { color: #2D3748; border-bottom: 2px solid #6B73FF; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📱 Aperçu des Captures d'Écran - Jubilé Tabernacle</h1>
EOF

# Ajouter les images à l'aperçu pour chaque format
for format_dir in "$OUTPUT_DIR"/*/; do
    if [ -d "$format_dir" ] && [ "$(basename "$format_dir")" != "clean" ]; then
        format_name=$(basename "$format_dir")
        echo "        <div class=\"section\">" >> "$OUTPUT_DIR/apercu.html"
        echo "            <h2>📱 $format_name</h2>" >> "$OUTPUT_DIR/apercu.html"
        echo "            <div class=\"grid\">" >> "$OUTPUT_DIR/apercu.html"
        
        for image in "$format_dir"/*.png; do
            if [ -f "$image" ]; then
                rel_path=$(realpath --relative-to="$OUTPUT_DIR" "$image")
                filename=$(basename "$image" .png)
                echo "                <div class=\"image-card\">" >> "$OUTPUT_DIR/apercu.html"
                echo "                    <img src=\"$rel_path\" alt=\"$filename\">" >> "$OUTPUT_DIR/apercu.html"
                echo "                    <h4>$filename</h4>" >> "$OUTPUT_DIR/apercu.html"
                echo "                </div>" >> "$OUTPUT_DIR/apercu.html"
            fi
        done
        
        echo "            </div>" >> "$OUTPUT_DIR/apercu.html"
        echo "        </div>" >> "$OUTPUT_DIR/apercu.html"
    fi
done

cat >> "$OUTPUT_DIR/apercu.html" << 'EOF'
    </div>
</body>
</html>
EOF

echo "🌐 Aperçu HTML généré: $OUTPUT_DIR/apercu.html"
echo "💡 Ouvrez le fichier dans votre navigateur pour voir toutes les captures"

# Instructions finales
cat << 'EOF'

🎯 PROCHAINES ÉTAPES:
====================

1. 📋 Vérifiez l'aperçu HTML généré
2. 🎨 Versions avec texte marketing: pour publicités
3. 🧹 Versions propres (dossier clean): pour stores
4. 📱 Upload sur App Store Connect et Google Play Console
5. 🧪 Testez l'affichage sur différents appareils

EOF
