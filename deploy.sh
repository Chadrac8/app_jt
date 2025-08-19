#!/bin/bash

# Script de déploiement automatisé pour l'application Flutter
# Usage: ./deploy.sh [environment]
# Environnements: dev, staging, prod

set -e

# Configuration
ENVIRONMENT=${1:-dev}
PROJECT_NAME="perfect-12"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
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

# Vérifications préalables
check_prerequisites() {
    print_message "Vérification des prérequis..."
    
    # Vérifier Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter n'est pas installé ou pas dans le PATH"
        exit 1
    fi
    
    # Vérifier Firebase CLI
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI n'est pas installé"
        print_message "Installez-le avec: npm install -g firebase-tools"
        exit 1
    fi
    
    # Vérifier la connexion Firebase
    if ! firebase projects:list &> /dev/null; then
        print_error "Vous n'êtes pas connecté à Firebase"
        print_message "Connectez-vous avec: firebase login"
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits"
}

# Nettoyer les builds précédents
clean_build() {
    print_message "Nettoyage des builds précédents..."
    flutter clean
    flutter pub get
    print_success "Nettoyage terminé"
}

# Construire l'application
build_app() {
    print_message "Construction de l'application pour le web..."
    
    # Configuration selon l'environnement
    case $ENVIRONMENT in
        "prod")
            print_message "Construction pour la production..."
            flutter build web --release --dart-define=ENVIRONMENT=production
            ;;
        "staging")
            print_message "Construction pour le staging..."
            flutter build web --release --dart-define=ENVIRONMENT=staging
            ;;
        "dev")
            print_message "Construction pour le développement..."
            flutter build web --release --dart-define=ENVIRONMENT=development
            ;;
        *)
            print_error "Environnement non reconnu: $ENVIRONMENT"
            print_message "Utilisez: dev, staging, ou prod"
            exit 1
            ;;
    esac
    
    print_success "Construction terminée"
}

# Déployer sur Firebase
deploy_firebase() {
    print_message "Déploiement sur Firebase Hosting..."
    
    case $ENVIRONMENT in
        "prod")
            firebase deploy --only hosting --project default
            ;;
        "staging")
            firebase hosting:channel:deploy staging --expires 30d --project default
            ;;
        "dev")
            firebase hosting:channel:deploy dev --expires 7d --project default
            ;;
    esac
    
    print_success "Déploiement terminé"
}

# Afficher les URLs de déploiement
show_urls() {
    print_message "URLs de déploiement:"
    
    case $ENVIRONMENT in
        "prod")
            echo -e "Production: ${GREEN}https://votre-domaine.com${NC}"
            echo -e "Firebase: ${GREEN}https://$PROJECT_NAME.web.app${NC}"
            ;;
        "staging")
            echo -e "Staging: ${YELLOW}https://$PROJECT_NAME--staging.web.app${NC}"
            ;;
        "dev")
            echo -e "Development: ${BLUE}https://$PROJECT_NAME--dev.web.app${NC}"
            ;;
    esac
}

# Fonction principale
main() {
    print_message "Début du déploiement pour l'environnement: $ENVIRONMENT"
    
    check_prerequisites
    clean_build
    build_app
    deploy_firebase
    show_urls
    
    print_success "Déploiement terminé avec succès!"
    print_message "Votre application est maintenant accessible via les URLs ci-dessus"
}

# Gestion des options
case "$1" in
    "-h"|"--help")
        echo "Usage: $0 [environment]"
        echo ""
        echo "Environnements disponibles:"
        echo "  dev      - Déploiement de développement (expires après 7 jours)"
        echo "  staging  - Déploiement de test (expires après 30 jours)"  
        echo "  prod     - Déploiement de production (permanent)"
        echo ""
        echo "Exemples:"
        echo "  $0 dev"
        echo "  $0 staging"
        echo "  $0 prod"
        exit 0
        ;;
    *)
        main
        ;;
esac
