#!/bin/bash

echo "⚪ VÉRIFICATION DU CERCLE BLANC POUR LE LOGO"
echo "============================================"
echo ""

echo "📋 Vérification des modifications apportées..."

# Vérification du Container avec décoration
echo ""
echo "1. CONTAINER AVEC CERCLE BLANC:"
if grep -q "Container" lib/widgets/bottom_navigation_wrapper.dart && grep -A5 -B5 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "Container"; then
    echo "   ✅ Container ajouté autour du logo"
else
    echo "   ❌ Container manquant"
fi

if grep -q "BoxDecoration" lib/widgets/bottom_navigation_wrapper.dart && grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "BoxDecoration"; then
    echo "   ✅ BoxDecoration présente"
else
    echo "   ❌ BoxDecoration manquante"
fi

if grep -q "color: Colors.white" lib/widgets/bottom_navigation_wrapper.dart && grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "Colors.white"; then
    echo "   ✅ Couleur blanche appliquée"
else
    echo "   ❌ Couleur blanche manquante"
fi

if grep -q "shape: BoxShape.circle" lib/widgets/bottom_navigation_wrapper.dart && grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "BoxShape.circle"; then
    echo "   ✅ Forme circulaire définie"
else
    echo "   ❌ Forme circulaire manquante"
fi

if grep -q "padding: const EdgeInsets.all" lib/widgets/bottom_navigation_wrapper.dart && grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "padding.*EdgeInsets.all"; then
    echo "   ✅ Padding intérieur ajouté"
else
    echo "   ❌ Padding intérieur manquant"
fi

# Vérification de l'image
echo ""
echo "2. IMAGE DU LOGO:"
if grep -q "fit: BoxFit.contain" lib/widgets/bottom_navigation_wrapper.dart && grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "BoxFit.contain"; then
    echo "   ✅ BoxFit.contain appliqué pour un bon ajustement"
else
    echo "   ❌ BoxFit.contain manquant"
fi

if grep -q "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart; then
    echo "   ✅ Chemin du logo inchangé"
else
    echo "   ❌ Chemin du logo modifié ou manquant"
fi

echo ""
echo "⚪ RÉSULTAT DE LA MODIFICATION:"
echo "==============================="

# Compter les éléments ajoutés
elements_count=0

if grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "Container"; then
    elements_count=$((elements_count + 1))
fi

if grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "BoxDecoration"; then
    elements_count=$((elements_count + 1))
fi

if grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "Colors.white"; then
    elements_count=$((elements_count + 1))
fi

if grep -A10 -B10 "assets/logo_jt.png" lib/widgets/bottom_navigation_wrapper.dart | grep -q "BoxShape.circle"; then
    elements_count=$((elements_count + 1))
fi

echo "• Éléments du cercle blanc: $elements_count/4"

if [ $elements_count -eq 4 ]; then
    echo ""
    echo "🎉 CERCLE BLANC APPLIQUÉ AVEC SUCCÈS!"
    echo ""
    echo "✨ CARACTÉRISTIQUES DU NOUVEAU LOGO:"
    echo "• Arrière-plan: Cercle blanc"
    echo "• Forme: BoxShape.circle"
    echo "• Padding: 4px intérieur"
    echo "• Image: Ajustée avec BoxFit.contain"
    echo "• Position: Leading de l'AppBar"
    echo ""
    echo "📱 APPARENCE ATTENDUE:"
    echo "• Logo dans un cercle blanc sur fond rouge bordeaux"
    echo "• Contraste amélioré et aspect plus professionnel"
    echo "• Logo bien centré dans le cercle"
else
    echo ""
    echo "⚠️  MODIFICATION INCOMPLÈTE"
    echo "Certains éléments du cercle blanc sont manquants."
fi

echo ""
echo "💡 Redémarrez l'application pour voir le logo avec son cercle blanc!"
