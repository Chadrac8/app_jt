#!/bin/bash

# Script de vérification pour app.jubiletabernacle.org
# Usage: ./verify-jubile.sh

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
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_jubile() {
    echo -e "${PURPLE}🏛️  [JUBILÉ]${NC} $1"
}

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🏛️        VÉRIFICATION JUBILÉ TABERNACLE APP               🏛️${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
print_jubile "Vérification de: $DOMAIN"
echo ""

# Vérification DNS
print_message "🔍 Vérification DNS..."

# Test de résolution CNAME
CNAME_RESULT=$(dig +short $DOMAIN CNAME)
if [ -n "$CNAME_RESULT" ]; then
    print_success "CNAME configuré: $CNAME_RESULT"
else
    print_warning "CNAME non trouvé ou pas encore propagé"
fi

# Test de résolution A
A_RESULT=$(dig +short $DOMAIN A)
if [ -n "$A_RESULT" ]; then
    print_success "Résolution A: $A_RESULT"
else
    print_warning "Résolution A non disponible"
fi

# Test de ping
print_message "🏓 Test de connectivité..."
if ping -c 1 $DOMAIN &> /dev/null; then
    print_success "Ping réussi"
else
    print_warning "Ping échoué - propagation DNS en cours"
fi

# Vérification HTTPS
print_message "🔒 Vérification HTTPS..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN --max-time 10 || echo "timeout")

case $HTTP_CODE in
    200)
        print_success "HTTPS fonctionne parfaitement"
        ;;
    301|302)
        print_success "Redirection HTTPS configurée"
        ;;
    timeout)
        print_warning "Timeout - site non accessible"
        ;;
    *)
        print_warning "Code HTTP: $HTTP_CODE"
        ;;
esac

# Vérification du certificat SSL
print_message "📜 Vérification du certificat SSL..."
SSL_INFO=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

if [ $? -eq 0 ]; then
    print_success "Certificat SSL valide"
    echo "$SSL_INFO" | sed 's/^/   /'
else
    print_warning "Certificat SSL non disponible ou invalide"
fi

# Test des principales pages
print_message "🌐 Test des principales pages..."

PAGES=("/" "/auth" "/dashboard")
for page in "${PAGES[@]}"; do
    PAGE_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN$page --max-time 5 || echo "timeout")
    if [ "$PAGE_CODE" = "200" ]; then
        print_success "Page $page accessible"
    else
        print_warning "Page $page: $PAGE_CODE"
    fi
done

# Vérification Firebase
print_message "🔥 Vérification Firebase..."
FIREBASE_HOSTING=$(curl -s -I https://$DOMAIN | grep -i "server:" | grep -i "firebase" || echo "")
if [ -n "$FIREBASE_HOSTING" ]; then
    print_success "Hébergé sur Firebase Hosting"
else
    print_warning "Serveur non identifié comme Firebase"
fi

# Performance basique
print_message "⚡ Test de performance basique..."
LOAD_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://$DOMAIN --max-time 10 || echo "timeout")
if [ "$LOAD_TIME" != "timeout" ]; then
    LOAD_TIME_MS=$(echo "$LOAD_TIME * 1000" | bc -l 2>/dev/null || echo "N/A")
    if (( $(echo "$LOAD_TIME < 3" | bc -l 2>/dev/null || echo 0) )); then
        print_success "Temps de chargement: ${LOAD_TIME}s (excellent)"
    else
        print_warning "Temps de chargement: ${LOAD_TIME}s (peut être optimisé)"
    fi
else
    print_warning "Impossible de mesurer le temps de chargement"
fi

# Résumé
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
print_jubile "RÉSUMÉ DE LA VÉRIFICATION"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"

if [ -n "$CNAME_RESULT" ] && [ "$HTTP_CODE" = "200" ]; then
    print_success "🎉 Votre application est en ligne et accessible!"
    print_jubile "URL: https://$DOMAIN"
elif [ -n "$CNAME_RESULT" ]; then
    print_warning "DNS configuré, mais site pas encore accessible"
    print_message "Attendez quelques heures pour la propagation complète"
else
    print_warning "Configuration DNS requise"
    echo ""
    echo "Configurez cet enregistrement DNS:"
    echo -e "${YELLOW}Type: CNAME${NC}"
    echo -e "${YELLOW}Nom: app${NC}"
    echo -e "${YELLOW}Valeur: $PROJECT_ID.web.app${NC}"
fi

echo ""
print_message "🔗 Outils de vérification en ligne:"
echo "• DNS Propagation: https://whatsmydns.net/#CNAME/$DOMAIN"
echo "• SSL Test: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo "• Speed Test: https://pagespeed.web.dev/report?url=https://$DOMAIN"
echo ""

# Option pour tests supplémentaires
read -p "🔍 Voulez-vous ouvrir les outils de test en ligne? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "Ouverture des outils de test..."
    open "https://whatsmydns.net/#CNAME/$DOMAIN"
    sleep 2
    open "https://pagespeed.web.dev/report?url=https://$DOMAIN"
fi

print_jubile "Vérification terminée! 🙏"
echo ""
