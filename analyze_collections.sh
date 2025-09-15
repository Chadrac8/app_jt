#!/bin/bash

echo "🔍 ANALYSE COMPARATIVE DES COLLECTIONS PEOPLE vs PERSONS"
echo "==========================================================="

# Analyser la collection 'people'
echo ""
echo "📊 ANALYSE DE LA COLLECTION 'people'"
echo "-------------------------------------"

# Compter les documents dans 'people'
people_count=$(firebase firestore:dump --only-collections people 2>/dev/null | jq -r 'keys | length' 2>/dev/null || echo "0")
echo "📝 Nombre de documents dans 'people': $people_count"

if [ "$people_count" -gt 0 ]; then
    echo "🔸 Analysing structure..."
    firebase firestore:dump --only-collections people --output-format json > /tmp/people_dump.json 2>/dev/null
    if [ -f /tmp/people_dump.json ]; then
        echo "   - Export des données 'people' réussi"
        # Analyser les champs les plus communs
        jq -r 'to_entries[] | .value | keys[]' /tmp/people_dump.json 2>/dev/null | sort | uniq -c | sort -nr | head -10 > /tmp/people_fields.txt
        echo "   - Champs les plus communs dans 'people':"
        cat /tmp/people_fields.txt | sed 's/^/     /'
    fi
fi

# Analyser la collection 'persons'
echo ""
echo "📊 ANALYSE DE LA COLLECTION 'persons'"
echo "--------------------------------------"

# Compter les documents dans 'persons'
persons_count=$(firebase firestore:dump --only-collections persons 2>/dev/null | jq -r 'keys | length' 2>/dev/null || echo "0")
echo "📝 Nombre de documents dans 'persons': $persons_count"

if [ "$persons_count" -gt 0 ]; then
    echo "🔸 Analysing structure..."
    firebase firestore:dump --only-collections persons --output-format json > /tmp/persons_dump.json 2>/dev/null
    if [ -f /tmp/persons_dump.json ]; then
        echo "   - Export des données 'persons' réussi"
        # Analyser les champs les plus communs
        jq -r 'to_entries[] | .value | keys[]' /tmp/persons_dump.json 2>/dev/null | sort | uniq -c | sort -nr | head -10 > /tmp/persons_fields.txt
        echo "   - Champs les plus communs dans 'persons':"
        cat /tmp/persons_fields.txt | sed 's/^/     /'
    fi
fi

# Comparaison
echo ""
echo "🔍 COMPARAISON DÉTAILLÉE"
echo "------------------------"
echo "Collection 'people':  $people_count documents"
echo "Collection 'persons': $persons_count documents"

# Déterminer la collection recommandée
if [ "$persons_count" -gt "$people_count" ]; then
    echo ""
    echo "✅ RECOMMANDATION: Utiliser 'persons' comme collection principale"
    echo "   Raisons:"
    echo "   - Plus de documents ($persons_count vs $people_count)"
    echo "   - Utilisée dans firebase_service.dart (service principal)"
    echo "   - Index Firestore configurés pour cette collection"
elif [ "$people_count" -gt "$persons_count" ]; then
    echo ""
    echo "⚠️  ATTENTION: 'people' contient plus de documents ($people_count vs $persons_count)"
    echo "   Mais 'persons' reste recommandée pour la cohérence du code"
elif [ "$people_count" -eq "$persons_count" ] && [ "$people_count" -gt 0 ]; then
    echo ""
    echo "🤔 Les deux collections ont le même nombre de documents"
    echo "   'persons' recommandée pour la cohérence architecturale"
else
    echo ""
    echo "📭 Une ou les deux collections sont vides"
fi

# Analyser les emails pour détecter les doublons si les fichiers existent
if [ -f /tmp/people_dump.json ] && [ -f /tmp/persons_dump.json ]; then
    echo ""
    echo "📧 ANALYSE DES EMAILS (détection de doublons)"
    echo "----------------------------------------------"
    
    # Extraire les emails de chaque collection
    jq -r 'to_entries[] | .value.email // empty' /tmp/people_dump.json 2>/dev/null | grep -v '^$' | sort > /tmp/people_emails.txt
    jq -r 'to_entries[] | .value.email // empty' /tmp/persons_dump.json 2>/dev/null | grep -v '^$' | sort > /tmp/persons_emails.txt
    
    people_emails=$(cat /tmp/people_emails.txt | wc -l)
    persons_emails=$(cat /tmp/persons_emails.txt | wc -l)
    common_emails=$(comm -12 /tmp/people_emails.txt /tmp/persons_emails.txt | wc -l)
    
    echo "   Emails dans 'people': $people_emails"
    echo "   Emails dans 'persons': $persons_emails"
    echo "   Emails communs: $common_emails"
    
    if [ "$common_emails" -gt 0 ]; then
        echo ""
        echo "⚠️  ATTENTION: $common_emails emails sont dupliqués entre les collections!"
        echo "   Exemples d'emails dupliqués:"
        comm -12 /tmp/people_emails.txt /tmp/persons_emails.txt | head -5 | sed 's/^/     - /'
    fi
fi

echo ""
echo "💡 ACTIONS SUGGÉRÉES:"
echo "1. Migrer les données uniques de 'people' vers 'persons'"
echo "2. Résoudre les doublons en fusionnant les informations"
echo "3. Mettre à jour improved_role_service.dart pour utiliser 'persons'"
echo "4. Supprimer la collection 'people' après migration"

echo ""
echo "✅ Analyse terminée!"

# Nettoyer les fichiers temporaires
rm -f /tmp/people_dump.json /tmp/persons_dump.json /tmp/people_fields.txt /tmp/persons_fields.txt /tmp/people_emails.txt /tmp/persons_emails.txt