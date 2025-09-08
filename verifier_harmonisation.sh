#!/bin/bash

echo "🔍 VÉRIFICATION DE L'HARMONISATION DES ONGLETS"
echo "================================================"
echo ""

echo "📋 Vérification des fichiers modifiés..."

# Vérification du module Le Message
echo ""
echo "1. MODULE LE MESSAGE:"
if grep -q "AppTheme.surfaceColor" lib/modules/message/message_module.dart; then
    echo "   ✅ Arrière-plan AppTheme.surfaceColor appliqué"
else
    echo "   ❌ Arrière-plan AppTheme.surfaceColor manquant"
fi

if grep -q "GoogleFonts.poppins" lib/modules/message/message_module.dart; then
    echo "   ✅ Police GoogleFonts.poppins appliquée"
else
    echo "   ❌ Police GoogleFonts.poppins manquante"
fi

if grep -q "BoxShadow" lib/modules/message/message_module.dart; then
    echo "   ✅ Ombres BoxShadow ajoutées"
else
    echo "   ❌ Ombres BoxShadow manquantes"
fi

# Vérification du module Songs/Cantiques
echo ""
echo "2. MODULE CANTIQUES/SONGS:"
if grep -q "AppTheme.surfaceColor" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Arrière-plan AppTheme.surfaceColor appliqué"
else
    echo "   ❌ Arrière-plan AppTheme.surfaceColor manquant"
fi

if grep -q "GoogleFonts.poppins" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Police GoogleFonts.poppins appliquée"
else
    echo "   ❌ Police GoogleFonts.poppins manquante"
fi

if grep -q "../../../theme.dart" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Import AppTheme ajouté"
else
    echo "   ❌ Import AppTheme manquant"
fi

# Vérification du module Vie de l'église (référence)
echo ""
echo "3. MODULE VIE DE L'ÉGLISE (référence):"
if grep -q "AppTheme.surfaceColor" lib/modules/vie_eglise/vie_eglise_module.dart; then
    echo "   ✅ Design de référence confirmé"
else
    echo "   ❌ Design de référence non trouvé"
fi

echo ""
echo "📊 RÉSUMÉ DE L'HARMONISATION:"
echo "=============================="

# Compter les fichiers modifiés
modified_files=0

if grep -q "AppTheme.surfaceColor" lib/modules/message/message_module.dart; then
    modified_files=$((modified_files + 1))
fi

if grep -q "AppTheme.surfaceColor" lib/modules/songs/views/songs_member_view.dart; then
    modified_files=$((modified_files + 1))
fi

echo "• Modules harmonisés: $modified_files/2"
echo "• Design de référence: Module Vie de l'église"
echo "• Éléments harmonisés:"
echo "  - Arrière-plan: AppTheme.surfaceColor (blanc)"
echo "  - Police: GoogleFonts.poppins()"
echo "  - Indicateur: AppTheme.primaryColor"
echo "  - Ombres: BoxShadow avec textTertiaryColor"
echo "  - Épaisseur indicateur: 3px"

if [ $modified_files -eq 2 ]; then
    echo ""
    echo "🎉 HARMONISATION RÉUSSIE!"
    echo "Tous les onglets des modules Membre ont maintenant le même design moderne."
else
    echo ""
    echo "⚠️  HARMONISATION INCOMPLÈTE"
    echo "Certaines modifications ne sont pas détectées."
fi

echo ""
echo "💡 Pour voir les changements, redémarrez l'application et naviguez vers les modules Le Message et Cantiques."
