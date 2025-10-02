#!/bin/bash

# Script pour configurer un appareil Android physique en mode sans fil
# Auteur: Assistant IA
# Date: 2 octobre 2025

echo "🔧 Configuration d'un appareil Android physique sans fil"
echo "================================================="

# Vérifier si ADB est installé
if ! command -v adb &> /dev/null; then
    echo "❌ ADB n'est pas installé. Installez Android SDK Platform Tools."
    echo "   Avec Homebrew: brew install android-platform-tools"
    exit 1
fi

echo "📱 Étape 1: Vérification des appareils connectés via USB"
echo "-------------------------------------------------------"
echo "Appareils connectés actuellement:"
adb devices

# Compter les appareils connectés
device_count=$(adb devices | grep -v "List of devices" | grep -c "device")
if [ $device_count -eq 0 ]; then
    echo "❌ Aucun appareil Android détecté."
    echo "   1. Connectez votre appareil via USB"
    echo "   2. Activez le débogage USB dans les Options développeur"
    echo "   3. Autorisez le débogage USB sur l'appareil"
    exit 1
fi

echo "✅ $device_count appareil(s) détecté(s)"

echo ""
echo "📶 Étape 2: Configuration du mode sans fil"
echo "-------------------------------------------"

# Configurer le port TCP pour la connexion WiFi
echo "Configuration du port TCP 5555..."
adb tcpip 5555

if [ $? -eq 0 ]; then
    echo "✅ Port TCP configuré avec succès"
else
    echo "❌ Erreur lors de la configuration du port TCP"
    exit 1
fi

echo ""
echo "🌐 Étape 3: Instructions pour la connexion WiFi"
echo "------------------------------------------------"
echo "1. Déconnectez maintenant le câble USB de votre appareil"
echo "2. Trouvez l'adresse IP de votre appareil Android:"
echo "   • Allez dans Paramètres > À propos du téléphone > État"
echo "   • Ou Paramètres > WiFi > Paramètres avancés"
echo "   • Notez l'adresse IP (ex: 192.168.1.100)"
echo ""
echo "3. Exécutez la commande suivante (remplacez XXX.XXX.XXX.XXX par votre IP):"
echo "   adb connect XXX.XXX.XXX.XXX:5555"
echo ""
echo "4. Vérifiez la connexion avec:"
echo "   adb devices"
echo ""

# Fonction pour tenter une connexion automatique (optionnel)
echo "💡 Voulez-vous essayer une connexion automatique? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Entrez l'adresse IP de votre appareil:"
    read -r ip_address
    
    if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Tentative de connexion à $ip_address:5555..."
        sleep 2  # Laisser le temps de débrancher le câble
        
        adb connect "$ip_address:5555"
        
        echo ""
        echo "📋 Vérification de la connexion:"
        adb devices
        
        if adb devices | grep -q "$ip_address:5555"; then
            echo "🎉 Connexion sans fil réussie !"
            echo ""
            echo "🚀 Vous pouvez maintenant lancer Flutter:"
            echo "   flutter devices"
            echo "   flutter run"
        else
            echo "❌ Connexion échouée. Vérifiez:"
            echo "   • L'adresse IP est correcte"
            echo "   • L'appareil et l'ordinateur sont sur le même réseau WiFi"
            echo "   • Le pare-feu n'bloque pas la connexion"
        fi
    else
        echo "❌ Adresse IP invalide"
    fi
fi

echo ""
echo "📝 Notes importantes:"
echo "• L'appareil et l'ordinateur doivent être sur le même réseau WiFi"
echo "• La connexion peut se perdre si l'appareil se met en veille"
echo "• Pour reconnecter: adb connect IP_ADDRESS:5555"
echo "• Pour revenir au mode USB: adb usb"
echo ""
echo "✨ Configuration terminée !"