#!/bin/bash

echo "🔧 Script de mise à jour automatique iOS Firebase"
echo "================================================="

# Configuration
BUNDLE_ID="com.jubiletabernacle.app"
PROJECT_ID="hjye25u8iwm0i0zls78urffsc0jcgj"
IOS_CONFIG_PATH="ios/Runner/GoogleService-Info.plist"
BACKUP_PATH="ios/Runner/GoogleService-Info.plist.backup"

echo "📱 Bundle ID: $BUNDLE_ID"
echo "🔥 Project ID: $PROJECT_ID"
echo ""

# 1. Sauvegarder l'ancien fichier
echo "1️⃣ Sauvegarde de l'ancien fichier..."
if [ -f "$IOS_CONFIG_PATH" ]; then
    cp "$IOS_CONFIG_PATH" "$BACKUP_PATH"
    echo "✅ Sauvegarde créée: $BACKUP_PATH"
else
    echo "⚠️  Aucun fichier existant trouvé"
fi

# 2. Instructions pour l'utilisateur
echo ""
echo "2️⃣ Instructions Firebase Console:"
echo "=================================="
echo ""
echo "🔗 Ouvrez: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo ""
echo "📋 Étapes à suivre:"
echo "1. Cliquez sur 'Add app' (+)"
echo "2. Sélectionnez l'icône iOS 🍎"
echo "3. Entrez le Bundle ID: $BUNDLE_ID"
echo "4. Cliquez 'Register app'"
echo "5. Téléchargez le GoogleService-Info.plist"
echo "6. Placez le fichier téléchargé dans ce dossier"
echo ""

# 3. Attendre le nouveau fichier
echo "3️⃣ En attente du nouveau fichier..."
echo "⏳ Placez le nouveau GoogleService-Info.plist dans ce dossier et appuyez sur ENTRÉE"
read -p "   Fichier téléchargé et placé? (y/n): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    # 4. Vérifier et installer le nouveau fichier
    if [ -f "GoogleService-Info.plist" ]; then
        echo "4️⃣ Installation du nouveau fichier..."
        cp "GoogleService-Info.plist" "$IOS_CONFIG_PATH"
        echo "✅ Nouveau fichier installé!"
        
        # 5. Vérification
        echo ""
        echo "5️⃣ Vérification de la configuration..."
        if grep -q "$BUNDLE_ID" "$IOS_CONFIG_PATH"; then
            echo "✅ Bundle ID correct"
        else
            echo "❌ Bundle ID incorrect dans le nouveau fichier"
            exit 1
        fi
        
        if grep -q "IS_GCM_ENABLED" "$IOS_CONFIG_PATH"; then
            echo "✅ Configuration FCM présente"
        else
            echo "❌ Configuration FCM manquante"
            exit 1
        fi
        
        echo ""
        echo "🎉 Configuration iOS mise à jour avec succès!"
        echo "📱 L'app peut maintenant générer des tokens FCM valides"
        
        # 6. Nettoyer
        rm -f "GoogleService-Info.plist" 2>/dev/null
        echo "🧹 Fichiers temporaires supprimés"
        
    else
        echo "❌ Fichier GoogleService-Info.plist non trouvé dans ce dossier"
        echo "💡 Assurez-vous de le télécharger depuis Firebase Console"
        exit 1
    fi
else
    echo "❌ Opération annulée"
    exit 1
fi

echo ""
echo "✨ Configuration terminée!"
echo "🔄 Redémarrez l'app pour que les changements prennent effet"
