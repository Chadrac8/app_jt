#!/bin/bash

# Script de configuration de domaine personnalisé
# Usage: ./setup-domain.sh mondomaine.com

set -e

DOMAIN=$1
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ -z "$DOMAIN" ]; then
    print_error "Usage: $0 <domaine>"
    print_message "Exemple: $0 mondomaine.com"
    exit 1
fi

print_message "Configuration du domaine personnalisé: $DOMAIN"

# Vérifier Firebase CLI
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI n'est pas installé"
    exit 1
fi

# Construire et déployer d'abord
print_message "Construction et déploiement de l'application..."
flutter build web --release
firebase deploy --only hosting

# Instructions pour la configuration DNS
print_message "Configuration DNS requise:"
echo ""
echo -e "${YELLOW}Configurez les enregistrements DNS suivants chez votre registrar:${NC}"
echo ""
echo "1. Domaine principal ($DOMAIN):"
echo "   Type: A"
echo "   Nom: @ (ou laissez vide)"
echo "   Valeur: Obtenez les IPs depuis la console Firebase"
echo ""
echo "2. Sous-domaine www:"
echo "   Type: CNAME"
echo "   Nom: www"
echo "   Valeur: $DOMAIN"
echo ""

print_message "Étapes à suivre:"
echo ""
echo "1. Allez sur https://console.firebase.google.com"
echo "2. Sélectionnez votre projet"
echo "3. Allez dans 'Hosting'"
echo "4. Cliquez sur 'Ajouter un domaine personnalisé'"
echo "5. Entrez: $DOMAIN"
echo "6. Suivez les instructions de vérification"
echo "7. Configurez les enregistrements DNS fournis"
echo ""

print_warning "La propagation DNS peut prendre 24-48 heures"
print_success "Configuration terminée!"

# Ouvrir la console Firebase
read -p "Voulez-vous ouvrir la console Firebase maintenant? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://console.firebase.google.com"
fi
