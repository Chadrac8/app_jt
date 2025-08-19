#!/bin/bash

echo "🔄 Mise à jour complète Firebase avec nouveau Bundle ID"
echo "======================================================"

# Nouveau Bundle ID
OLD_BUNDLE_ID="com.mycompany.Personnes"
NEW_BUNDLE_ID="com.jubiletabernacle.app"
PROJECT_ID="hjye25u8iwm0i0zls78urffsc0jcgj"

echo "📱 Ancien Bundle ID: $OLD_BUNDLE_ID"
echo "📱 Nouveau Bundle ID: $NEW_BUNDLE_ID"
echo "🔥 Project ID: $PROJECT_ID"
echo ""

# 1. Sauvegarde
echo "1️⃣ Sauvegarde des fichiers existants..."
cp ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.backup 2>/dev/null || echo "⚠️  Pas de fichier à sauvegarder"

# 2. Instructions Firebase Console
echo ""
echo "2️⃣ ÉTAPES FIREBASE CONSOLE:"
echo "=========================="
echo ""
echo "🔗 Ouvrez: https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "📋 OPTION A - Modifier l'app existante (recommandé):"
echo "1. Allez dans 'Project Settings' ⚙️"
echo "2. Dans 'Your apps', trouvez l'app iOS existante"
echo "3. Cliquez sur l'icône ⚙️ de l'app iOS"
echo "4. Modifiez le Bundle ID de '$OLD_BUNDLE_ID' vers '$NEW_BUNDLE_ID'"
echo "5. Téléchargez le nouveau GoogleService-Info.plist"
echo ""
echo "📋 OPTION B - Supprimer et recréer:"
echo "1. Supprimez l'ancienne app iOS (si possible)"
echo "2. Cliquez 'Add app' → iOS 🍎"
echo "3. Bundle ID: $NEW_BUNDLE_ID"
echo "4. Téléchargez GoogleService-Info.plist"
echo ""

# 3. Ouvrir automatiquement Firebase Console
echo "3️⃣ Ouverture de Firebase Console..."
if command -v open >/dev/null 2>&1; then
    open "https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
    echo "✅ Firebase Console ouvert dans le navigateur"
else
    echo "⚠️  Veuillez ouvrir manuellement: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
fi

echo ""
echo "4️⃣ Une fois le nouveau GoogleService-Info.plist téléchargé:"
echo "==========================================================="
echo "1. Placez le fichier dans ce dossier (perfect 13/)"
echo "2. Appuyez sur ENTRÉE pour continuer..."
read -p "Fichier téléchargé? (y/n): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo ""
    echo "5️⃣ Installation du nouveau fichier..."
    
    if [ -f "GoogleService-Info.plist" ]; then
        # Vérifier que le Bundle ID est correct dans le nouveau fichier
        if grep -q "$NEW_BUNDLE_ID" "GoogleService-Info.plist"; then
            cp "GoogleService-Info.plist" "ios/Runner/GoogleService-Info.plist"
            echo "✅ Nouveau GoogleService-Info.plist installé!"
            
            # Nettoyer le fichier temporaire
            rm "GoogleService-Info.plist"
            
            echo ""
            echo "6️⃣ Vérification finale..."
            if grep -q "$NEW_BUNDLE_ID" "ios/Runner/GoogleService-Info.plist"; then
                echo "✅ Bundle ID correct: $NEW_BUNDLE_ID"
            else
                echo "❌ Bundle ID incorrect dans le fichier"
                exit 1
            fi
            
            if grep -q "IS_GCM_ENABLED" "ios/Runner/GoogleService-Info.plist"; then
                echo "✅ Configuration FCM activée"
            else
                echo "❌ Configuration FCM manquante"
                exit 1
            fi
            
            echo ""
            echo "🎉 MISE À JOUR RÉUSSIE!"
            echo "======================"
            echo "✅ Bundle ID mis à jour: $NEW_BUNDLE_ID"
            echo "✅ Configuration Firebase mise à jour"
            echo "✅ FCM activé pour les notifications push"
            echo ""
            echo "🔄 PROCHAINES ÉTAPES:"
            echo "1. Redémarrez l'app Flutter"
            echo "2. Les nouveaux tokens FCM seront générés automatiquement"
            echo "3. Testez les notifications push"
            
        else
            echo "❌ Le fichier GoogleService-Info.plist ne contient pas le bon Bundle ID"
            echo "💡 Vérifiez que vous avez téléchargé le bon fichier depuis Firebase"
            exit 1
        fi
    else
        echo "❌ GoogleService-Info.plist non trouvé dans ce dossier"
        echo "💡 Téléchargez-le depuis Firebase Console et placez-le ici"
        exit 1
    fi
else
    echo "❌ Opération annulée"
    exit 1
fi

echo ""
echo "✨ Configuration terminée avec succès!"
echo "🚀 Votre app peut maintenant recevoir des notifications push!"
