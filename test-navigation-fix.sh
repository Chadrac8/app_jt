#!/bin/bash

echo "=== Test de validation de la bottom navigation ==="
echo ""

echo "1. Vérification du fichier bottom_navigation_wrapper.dart..."
if grep -q "int maxPrimaryItems = hasMoreItems ? 4 : 5;" "/Users/chadracntsouassouani/Downloads/perfect 13/lib/widgets/bottom_navigation_wrapper.dart"; then
    echo "✅ Logique maxPrimaryItems correcte"
else
    echo "❌ Logique maxPrimaryItems manquante"
fi

if grep -q "_overflowPrimaryItems" "/Users/chadracntsouassouani/Downloads/perfect 13/lib/widgets/bottom_navigation_wrapper.dart"; then
    echo "✅ Variable _overflowPrimaryItems présente"
else
    echo "❌ Variable _overflowPrimaryItems manquante"
fi

echo ""
echo "2. Test de la logique avec dart..."
cd "/Users/chadracntsouassouani/Downloads/perfect 13"
dart test_nav_logic_simple.dart

echo ""
echo "3. Vérification de l'intégration du module Dons..."
if grep -q "DonsAdminView" "/Users/chadracntsouassouani/Downloads/perfect 13/lib/services/app_config_firebase_service.dart"; then
    echo "✅ Module Dons intégré dans la configuration"
else
    echo "❌ Module Dons non intégré"
fi

echo ""
echo "=== Fin des tests ==="
