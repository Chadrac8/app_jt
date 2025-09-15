#!/bin/bash

echo "🔍 VÉRIFICATION DES RÉFÉRENCES RESTANTES À 'people'"
echo "=================================================="

echo ""
echo "📁 Recherche dans les services principaux..."
find lib/services -name "*.dart" -exec grep -l "collection('people')" {} \; 2>/dev/null | while read file; do
    echo "⚠️  Référence trouvée dans: $file"
    grep -n "collection('people')" "$file"
done

echo ""
echo "📁 Recherche dans les pages..."
find lib/pages -name "*.dart" -exec grep -l "collection('people')" {} \; 2>/dev/null | while read file; do
    echo "⚠️  Référence trouvée dans: $file"
    grep -n "collection('people')" "$file"
done

echo ""
echo "📁 Recherche dans les modèles..."
find lib/models -name "*.dart" -exec grep -l "collection('people')" {} \; 2>/dev/null | while read file; do
    echo "⚠️  Référence trouvée dans: $file"
    grep -n "collection('people')" "$file"
done

echo ""
echo "📁 Recherche dans les widgets..."
find lib/widgets -name "*.dart" -exec grep -l "collection('people')" {} \; 2>/dev/null | while read file; do
    echo "⚠️  Référence trouvée dans: $file"
    grep -n "collection('people')" "$file"
done

echo ""
echo "🔧 Recherche des constantes 'peopleCollection'..."
find lib -name "*.dart" -exec grep -l "peopleCollection\|'people'" {} \; 2>/dev/null | while read file; do
    echo "📋 Fichier à vérifier: $file"
    grep -n "peopleCollection\|'people'" "$file" | head -3
done

echo ""
echo "✅ Vérification terminée!"
echo "Si aucun fichier n'est listé ci-dessus, toutes les références ont été mises à jour."