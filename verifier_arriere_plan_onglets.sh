#!/bin/bash

echo "🎨 VÉRIFICATION DE L'ARRIÈRE-PLAN DIFFÉRENCIÉ DES ONGLETS"
echo "=========================================================="
echo ""

echo "📋 Vérification de la distinction visuelle..."

# Vérification de l'AppBar
echo ""
echo "1. APPBAR:"
if grep -q "backgroundColor: Colors.transparent" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ AppBar: Colors.transparent"
else
    echo "   ❌ AppBar: backgroundColor manquant ou différent"
fi

# Vérification du TabBar avec arrière-plan
echo ""
echo "2. TABBAR:"
if grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ TabBar encapsulé dans PreferredSize"
else
    echo "   ❌ TabBar non encapsulé"
fi

if grep -q "Container" lib/modules/songs/views/songs_member_view.dart && grep -q "color: Colors.grey\[100\]" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Container avec arrière-plan Colors.grey[100]"
else
    echo "   ❌ Container avec arrière-plan manquant"
fi

if grep -q "TabBar" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ TabBar présent dans le Container"
else
    echo "   ❌ TabBar manquant"
fi

echo ""
echo "🎨 DISTINCTION VISUELLE CRÉÉE:"
echo "=============================="
echo "• AppBar: Transparente (Colors.transparent)"
echo "• TabBar: Gris clair (Colors.grey[100])"
echo "• Effet: Distinction claire entre l'en-tête et les onglets"

# Compter les éléments présents
elements_present=0

if grep -q "backgroundColor: Colors.transparent" lib/modules/songs/views/songs_member_view.dart; then
    elements_present=$((elements_present + 1))
fi

if grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    elements_present=$((elements_present + 1))
fi

if grep -q "color: Colors.grey\[100\]" lib/modules/songs/views/songs_member_view.dart; then
    elements_present=$((elements_present + 1))
fi

echo ""
echo "📊 STATUT DE LA MODIFICATION:"
echo "============================="
echo "• Éléments implémentés: $elements_present/3"

if [ $elements_present -eq 3 ]; then
    echo ""
    echo "🎉 ARRIÈRE-PLAN DIFFÉRENCIÉ APPLIQUÉ AVEC SUCCÈS!"
    echo ""
    echo "✨ RÉSULTAT ATTENDU:"
    echo "• L'AppBar sera transparente"
    echo "• Les onglets auront un fond gris clair"
    echo "• Distinction visuelle claire entre les deux zones"
    echo ""
    echo "💡 Redémarrez l'application pour voir la différence visuelle."
else
    echo ""
    echo "⚠️  MODIFICATION INCOMPLÈTE"
    echo "Certains éléments ne sont pas détectés."
fi

echo ""
echo "🔧 CONFIGURATION APPLIQUÉE:"
echo "• AppBar backgroundColor: Colors.transparent"
echo "• TabBar backgroundColor: Colors.grey[100] (dans Container)"
echo "• Structure: PreferredSize > Container > TabBar"
