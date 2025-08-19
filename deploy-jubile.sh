#!/bin/bash

# Script de déploiement pour app.jubiletabernacle.org
# Usage: ./deploy-jubile.sh

set -e

DOMAIN="app.jubiletabernacle.org"
PROJECT_ID="hjye25u8iwm0i0zls78urffsc0jcgj"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_jubile() {
    echo -e "${PURPLE}🏛️  [JUBILÉ TABERNACLE]${NC} $1"
}

# En-tête
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🏛️           DÉPLOIEMENT JUBILÉ TABERNACLE APP             🏛️${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
print_jubile "Domaine cible: $DOMAIN"
print_jubile "Projet Firebase: $PROJECT_ID"
echo ""

# Vérifications
print_message "Vérification des prérequis..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter n'est pas installé"
    exit 1
fi

if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI n'est pas installé"
    print_message "Installez avec: npm install -g firebase-tools"
    exit 1
fi

print_success "Prérequis vérifiés"

# Construction
print_message "🔨 Construction de l'application..."
flutter clean
flutter pub get
flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=DOMAIN=$DOMAIN

if [ $? -eq 0 ]; then
    print_success "Construction terminée avec succès"
else
    print_error "Erreur lors de la construction"
    exit 1
fi

# Déploiement
print_message "🚀 Déploiement sur Firebase Hosting..."
firebase use $PROJECT_ID
firebase deploy --only hosting --project $PROJECT_ID

if [ $? -eq 0 ]; then
    print_success "Déploiement réussi!"
else
    print_error "Erreur lors du déploiement"
    exit 1
fi

# Instructions post-déploiement
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
print_jubile "DÉPLOIEMENT TERMINÉ AVEC SUCCÈS!"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

print_message "🌐 URLs de votre application:"
echo -e "   • URL temporaire: ${GREEN}https://$PROJECT_ID.web.app${NC}"
echo -e "   • URL finale: ${GREEN}https://$DOMAIN${NC}"
echo ""

print_warning "📋 CONFIGURATION DNS REQUISE:"
echo "Configurez cet enregistrement chez votre registrar de domaine:"
echo ""
echo -e "${YELLOW}Type: CNAME${NC}"
echo -e "${YELLOW}Nom: app${NC}"
echo -e "${YELLOW}Valeur: $PROJECT_ID.web.app${NC}"
echo -e "${YELLOW}TTL: 3600${NC}"
echo ""

print_message "📱 Étapes suivantes:"
echo "1. Ajoutez le domaine dans Firebase Console"
echo "2. Configurez l'enregistrement DNS CNAME"
echo "3. Attendez la propagation DNS (24-48h max)"
echo "4. Votre app sera accessible à https://$DOMAIN"
echo ""

print_message "🔗 Liens utiles:"
echo "• Console Firebase: https://console.firebase.google.com/project/$PROJECT_ID/hosting/main"
echo "• Test DNS: https://whatsmydns.net/#CNAME/$DOMAIN"
echo "• Documentation: ./CONFIGURATION-JUBILE-DOMAINE.md"
echo ""

# Option pour ouvrir la console
read -p "🔥 Voulez-vous ouvrir la console Firebase pour ajouter le domaine? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "Ouverture de la console Firebase..."
    open "https://console.firebase.google.com/project/$PROJECT_ID/hosting/main"
fi

print_jubile "Que Dieu bénisse votre ministère numérique! 🙏"
echo ""
