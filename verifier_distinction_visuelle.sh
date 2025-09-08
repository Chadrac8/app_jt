#!/bin/bash

echo "🔍 VÉRIFICATION DE LA DISTINCTION VISUELLE DES ONGLETS"
echo "======================================================"
echo ""

echo "📋 Comparaison des propriétés visuelles..."

# Vérification du module La Bible (référence)
echo ""
echo "1. MODULE LA BIBLE (référence):"
if grep -q "backgroundColor: Colors.transparent" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ AppBar transparente"
else
    echo "   ❌ AppBar transparente non trouvée"
fi

if grep -q "elevation: 0" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ Élévation 0 pour AppBar"
else
    echo "   ❌ Élévation 0 manquante"
fi

if grep -q "bottom: TabBar" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ TabBar direct dans AppBar"
else
    echo "   ❌ TabBar dans AppBar non trouvé"
fi

# Vérification du module Cantiques (modifié)
echo ""
echo "2. MODULE CANTIQUES (modifié):"
if grep -q "backgroundColor: AppTheme.surfaceColor" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ AppBar avec arrière-plan surfaceColor"
else
    echo "   ❌ AppBar avec arrière-plan surfaceColor manquant"
fi

if grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ TabBar encapsulé dans PreferredSize"
else
    echo "   ❌ TabBar encapsulé manquant"
fi

if grep -q "Colors.grey\[50\]" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Arrière-plan TabBar différencié (grey[50])"
else
    echo "   ❌ Arrière-plan TabBar différencié manquant"
fi

if grep -q "Container.*color.*TabBar" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Container avec couleur pour distinction visuelle"
else
    echo "   ❌ Container avec couleur manquant"
fi

echo ""
echo "📊 ANALYSE DE LA DISTINCTION VISUELLE:"
echo "====================================="

echo "• Module La Bible : AppBar transparente + TabBar par défaut"
echo "• Module Cantiques : AppBar surfaceColor + TabBar avec fond grey[50]"
echo ""
echo "✨ DIFFÉRENCES VISUELLES ATTENDUES:"
echo "• AppBar : Couleur de fond différente entre les modules"
echo "• TabBar : Fond légèrement gris pour se distinguer de l'AppBar"
echo "• Séparation : Distinction claire entre l'en-tête et les onglets"

# Vérification que toutes les modifications sont présentes
modifications_present=0

if grep -q "backgroundColor: AppTheme.surfaceColor" lib/modules/songs/views/songs_member_view.dart; then
    modifications_present=$((modifications_present + 1))
fi

if grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    modifications_present=$((modifications_present + 1))
fi

if grep -q "Colors.grey\[50\]" lib/modules/songs/views/songs_member_view.dart; then
    modifications_present=$((modifications_present + 1))
fi

if [ $modifications_present -eq 3 ]; then
    echo ""
    echo "🎉 DISTINCTION VISUELLE AMÉLIORÉE!"
    echo "Les onglets devraient maintenant se distinguer clairement de l'AppBar."
else
    echo ""
    echo "⚠️  MODIFICATIONS INCOMPLÈTES"
    echo "Certaines améliorations visuelles ne sont pas détectées."
fi

echo ""
echo "💡 Redémarrez l'application pour voir la différence visuelle entre l'AppBar et les onglets."
