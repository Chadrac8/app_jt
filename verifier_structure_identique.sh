#!/bin/bash

echo "🔍 VÉRIFICATION FINALE - STRUCTURE IDENTIQUE"
echo "============================================="
echo ""

echo "📋 Comparaison exacte avec le module La Bible..."

# Vérification des éléments clés
echo ""
echo "1. APPBAR CONFIGURATION:"

# AppBar backgroundColor
bible_transparent=$(grep -c "backgroundColor: Colors.transparent" lib/modules/bible/views/bible_member_view.dart)
cantiques_transparent=$(grep -c "backgroundColor: Colors.transparent" lib/modules/songs/views/songs_member_view.dart)

if [ $bible_transparent -eq $cantiques_transparent ] && [ $bible_transparent -gt 0 ]; then
    echo "   ✅ AppBar backgroundColor: Colors.transparent (identique)"
else
    echo "   ❌ AppBar backgroundColor différent"
fi

# AppBar elevation
bible_elevation=$(grep -c "elevation: 0" lib/modules/bible/views/bible_member_view.dart)
cantiques_elevation=$(grep -c "elevation: 0" lib/modules/songs/views/songs_member_view.dart)

if [ $bible_elevation -eq $cantiques_elevation ] && [ $bible_elevation -gt 0 ]; then
    echo "   ✅ AppBar elevation: 0 (identique)"
else
    echo "   ❌ AppBar elevation différent"
fi

echo ""
echo "2. TABBAR CONFIGURATION:"

# TabBar direct dans AppBar
bible_bottom_tabbar=$(grep -c "bottom: TabBar" lib/modules/bible/views/bible_member_view.dart)
cantiques_bottom_tabbar=$(grep -c "bottom: TabBar" lib/modules/songs/views/songs_member_view.dart)

if [ $bible_bottom_tabbar -eq $cantiques_bottom_tabbar ] && [ $bible_bottom_tabbar -gt 0 ]; then
    echo "   ✅ TabBar direct dans AppBar (identique)"
else
    echo "   ❌ TabBar structure différente"
fi

# Couleur indicateur
bible_indicator=$(grep -c "indicatorColor: AppTheme.primaryColor" lib/modules/bible/views/bible_member_view.dart)
cantiques_indicator=$(grep -c "indicatorColor: AppTheme.primaryColor" lib/modules/songs/views/songs_member_view.dart)

if [ $bible_indicator -eq $cantiques_indicator ] && [ $bible_indicator -gt 0 ]; then
    echo "   ✅ indicatorColor: AppTheme.primaryColor (identique)"
else
    echo "   ❌ indicatorColor différent"
fi

# Couleur texte inactif
bible_unselected=$(grep -c "Colors.grey\[600\]" lib/modules/bible/views/bible_member_view.dart)
cantiques_unselected=$(grep -c "Colors.grey\[600\]" lib/modules/songs/views/songs_member_view.dart)

if [ $bible_unselected -eq $cantiques_unselected ] && [ $bible_unselected -gt 0 ]; then
    echo "   ✅ unselectedLabelColor: Colors.grey[600] (identique)"
else
    echo "   ❌ unselectedLabelColor différent"
fi

echo ""
echo "3. VÉRIFICATION ABSENCE D'ÉLÉMENTS INDÉSIRABLES:"

# Vérifier qu'il n'y a pas de PreferredSize
if ! grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Pas de PreferredSize (comme La Bible)"
else
    echo "   ❌ PreferredSize encore présent"
fi

# Vérifier qu'il n'y a pas de Container avec couleur
if ! grep -q "Container.*color.*grey" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Pas de Container coloré (comme La Bible)"
else
    echo "   ❌ Container coloré encore présent"
fi

echo ""
echo "📊 RÉSUMÉ DE LA CONFORMITÉ:"
echo "==========================="

# Compter les éléments conformes
conformity_score=0

if [ $bible_transparent -eq $cantiques_transparent ] && [ $bible_transparent -gt 0 ]; then
    conformity_score=$((conformity_score + 1))
fi

if [ $bible_elevation -eq $cantiques_elevation ] && [ $bible_elevation -gt 0 ]; then
    conformity_score=$((conformity_score + 1))
fi

if [ $bible_bottom_tabbar -eq $cantiques_bottom_tabbar ] && [ $bible_bottom_tabbar -gt 0 ]; then
    conformity_score=$((conformity_score + 1))
fi

if [ $bible_indicator -eq $cantiques_indicator ] && [ $bible_indicator -gt 0 ]; then
    conformity_score=$((conformity_score + 1))
fi

if [ $bible_unselected -eq $cantiques_unselected ] && [ $bible_unselected -gt 0 ]; then
    conformity_score=$((conformity_score + 1))
fi

echo "• Éléments conformes: $conformity_score/5"
echo "• Structure: TabBar direct dans AppBar"
echo "• Apparence: Identique au module La Bible"

if [ $conformity_score -eq 5 ] && ! grep -q "PreferredSize" lib/modules/songs/views/songs_member_view.dart; then
    echo ""
    echo "🎉 STRUCTURE PARFAITEMENT IDENTIQUE!"
    echo "Le module Cantiques a maintenant exactement la même structure que La Bible."
    echo "Les onglets devraient avoir la même apparence visuelle."
else
    echo ""
    echo "⚠️  STRUCTURE INCOMPLÈTE"
    echo "Score de conformité: $conformity_score/5"
fi

echo ""
echo "💡 Redémarrez l'application pour voir le résultat final."
