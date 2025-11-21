import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

/// Widget pour sélectionner une icône parmi une large collection
class IconSelector extends StatefulWidget {
  final String currentIcon;
  final Function(String) onIconSelected;

  const IconSelector({
    super.key,
    required this.currentIcon,
    required this.onIconSelected,
  });

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  String _searchQuery = '';
  List<IconOption> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _filteredIcons = _getAllIcons();
  }

  void _filterIcons(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredIcons = _getAllIcons();
      } else {
        _filteredIcons = _getAllIcons()
            .where((icon) => 
                icon.name.toLowerCase().contains(query.toLowerCase()) ||
                icon.keywords.any((keyword) => 
                    keyword.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette, color: AppTheme.white100),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Sélectionner une icône',
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.white100,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.white100),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: TextField(
                onChanged: _filterIcons,
                decoration: InputDecoration(
                  hintText: 'Rechercher une icône...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey50,
                ),
              ),
            ),
            
            // Current selection info
            if (widget.currentIcon.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconData(widget.currentIcon),
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Actuellement sélectionné: ${widget.currentIcon}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Icons grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _filteredIcons.length,
                  itemBuilder: (context, index) {
                    final iconOption = _filteredIcons[index];
                    final isSelected = iconOption.name == widget.currentIcon;
                    
                    return                      Tooltip(
                        message: '${iconOption.name}\n${iconOption.description}',
                      child: InkWell(
                        onTap: () {
                          widget.onIconSelected(iconOption.name);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : AppTheme.grey50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.grey300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            iconOption.iconData,
                            color: isSelected 
                                ? AppTheme.white100 
                                : AppTheme.textPrimaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Footer with count
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Text(
                '${_filteredIcons.length} icône(s) trouvée(s)',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: AppTheme.fontSize14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir l'IconData à partir du nom d'icône
  IconData _getIconData(String iconName) {
    final iconOption = _getAllIcons().firstWhere(
      (icon) => icon.name == iconName,
      orElse: () => IconOption('apps', Icons.apps, 'Applications', []),
    );
    return iconOption.iconData;
  }

  /// Liste complète des icônes disponibles
  List<IconOption> _getAllIcons() {
    return [
      // Personnes et groupes
      IconOption('people', Icons.people, 'Personnes', ['utilisateurs', 'membres', 'groupe']),
      IconOption('person', Icons.person, 'Personne', ['utilisateur', 'profil', 'individu']),
      IconOption('groups', Icons.groups, 'Groupes', ['équipes', 'communauté', 'ensemble']),
      IconOption('group_add', Icons.group_add, 'Ajouter groupe', ['nouveau', 'créer', 'plus']),
      IconOption('person_add', Icons.person_add, 'Ajouter personne', ['nouveau', 'inscrit', 'membre']),
      IconOption('family_restroom', Icons.family_restroom, 'Famille', ['parents', 'enfants', 'foyer']),
      IconOption('diversity_1', Icons.diversity_1, 'Diversité', ['inclusion', 'communauté', 'unité']),
      IconOption('supervisor_account', Icons.supervisor_account, 'Superviseur', ['responsable', 'leader', 'chef']),
      IconOption('account_circle', Icons.account_circle, 'Compte', ['profil', 'utilisateur', 'connexion']),
      IconOption('face', Icons.face, 'Visage', ['personne', 'portrait', 'identité']),

      // Événements et calendrier
      IconOption('event', Icons.event, 'Événement', ['programme', 'activité', 'rendez-vous']),
      IconOption('calendar_today', Icons.calendar_today, 'Calendrier', ['date', 'planning', 'horaire']),
      IconOption('calendar_month', Icons.calendar_month, 'Calendrier mensuel', ['mois', 'planning', 'vue']),
      IconOption('event_available', Icons.event_available, 'Événement disponible', ['libre', 'ouvert', 'possible']),
      IconOption('event_busy', Icons.event_busy, 'Événement occupé', ['complet', 'réservé', 'indisponible']),
      IconOption('schedule', Icons.schedule, 'Horaire', ['temps', 'planning', 'programme']),
      IconOption('today', Icons.today, 'Aujourd\'hui', ['maintenant', 'présent', 'actuel']),
      IconOption('date_range', Icons.date_range, 'Période', ['durée', 'intervalle', 'plage']),
      IconOption('access_time', Icons.access_time, 'Heure', ['temps', 'horloge', 'horaire']),
      IconOption('timer', Icons.timer, 'Minuteur', ['compte', 'durée', 'temps']),

      // Religion et spiritualité
      IconOption('church', Icons.church, 'Église', ['temple', 'sanctuaire', 'culte']),
      IconOption('menu_book', Icons.menu_book, 'Bible', ['livre', 'lecture', 'étude']),
      IconOption('book', Icons.book, 'Bible fermée', ['livre', 'fermé', 'bible', 'lecture']),
      IconOption('import_contacts', Icons.import_contacts, 'Bible ouverte', ['livre', 'ouvert', 'bible', 'lecture', 'pages']),
      IconOption('auto_stories', Icons.auto_stories, 'Saintes Écritures', ['écritures', 'récits', 'témoignages', 'narration', 'bible']),
      IconOption('add', Icons.add, 'Croix', ['croix', 'christ', 'salut', 'sacrifice', 'christianisme']),
      IconOption('close', Icons.close, 'Croix alternative', ['croix', 'christ', 'sacrifice', 'christianisme', 'plus']),
      IconOption('medical_services', Icons.medical_services, 'Croix de vie', ['croix', 'vie', 'guérison', 'salut', 'santé']),
      IconOption('library_books', Icons.library_books, 'Bibliothèque', ['collection', 'livres', 'ressources']),
      IconOption('favorite', Icons.favorite, 'Prière', ['cœur', 'amour', 'spiritualité']),
      IconOption('volunteer_activism', Icons.volunteer_activism, 'Service', ['bénévolat', 'aide', 'don']),
      IconOption('handshake', Icons.handshake, 'Partenariat', ['accord', 'collaboration', 'alliance']),
      IconOption('emoji_people', Icons.emoji_people, 'Communauté', ['joie', 'ensemble', 'unité']),
      IconOption('celebration', Icons.celebration, 'Célébration', ['fête', 'joie', 'festival']),
      
      // Nouvelles icônes spirituelles étendues
      IconOption('self_improvement', Icons.self_improvement, 'Méditation/Prière', ['méditation', 'prière', 'spiritualité', 'contemplation']),
      IconOption('psychology', Icons.psychology, 'Âme/Esprit', ['âme', 'esprit', 'pensée', 'mental', 'spirituel']),
      IconOption('healing', Icons.healing, 'Guérison', ['guérison', 'santé', 'restauration', 'bien-être', 'miracle']),
      IconOption('diversity_3', Icons.diversity_3, 'Communion', ['communion', 'fellowship', 'unité', 'fraternité']),
      IconOption('local_fire_department', Icons.local_fire_department, 'Feu de l\'Esprit', ['feu', 'esprit', 'saint', 'onction', 'puissance']),
      IconOption('water_drop', Icons.water_drop, 'Baptême', ['baptême', 'eau', 'purification', 'renaissance']),
      IconOption('sentiment_very_satisfied', Icons.sentiment_very_satisfied, 'Joie spirituelle', ['joie', 'bonheur', 'paix', 'contentement']),
      IconOption('eco', Icons.eco, 'Croissance spirituelle', ['croissance', 'développement', 'maturité', 'fruit']),
      IconOption('local_florist', Icons.local_florist, 'Fleur de foi', ['fleur', 'beauté', 'création', 'nature']),
      IconOption('nights_stay', Icons.nights_stay, 'Veillée/Nuit de prière', ['veillée', 'nuit', 'prière', 'lune']),
      IconOption('campaign', Icons.campaign, 'Évangélisation', ['évangélisation', 'proclamation', 'témoignage', 'annonce']),
      IconOption('grade', Icons.grade, 'Étoile spirituelle', ['étoile', 'david', 'symbole', 'guide']),
      IconOption('brightness_7', Icons.brightness_7, 'Gloire divine', ['gloire', 'rayonnement', 'majesté', 'divinité']),
      IconOption('spa', Icons.spa, 'Paix intérieure', ['paix', 'sérénité', 'calme', 'tranquillité']),
      IconOption('child_care', Icons.child_care, 'Enfants de Dieu', ['enfants', 'jeunesse', 'innocence', 'pureté']),
      IconOption('diversity_1', Icons.diversity_1, 'Diversité dans l\'unité', ['diversité', 'unité', 'inclusion', 'amour']),
      IconOption('forum', Icons.forum, 'Témoignage', ['témoignage', 'partage', 'discussion', 'conversation']),
      IconOption('record_voice_over', Icons.record_voice_over, 'Prédication', ['prédication', 'sermon', 'enseignement', 'parole']),
      IconOption('sentiment_satisfied_alt', Icons.sentiment_satisfied_alt, 'Béatitude', ['béatitude', 'bonheur', 'bénédiction', 'satisfaction']),
      IconOption('auto_awesome', Icons.auto_awesome, 'Miracles', ['miracle', 'divin', 'puissance', 'bénédiction']),
      IconOption('wb_sunny', Icons.wb_sunny, 'Lumière divine', ['lumière', 'divin', 'soleil', 'gloire']),
      IconOption('light_mode', Icons.light_mode, 'Clarté spirituelle', ['clarté', 'illumination', 'révélation']),
      IconOption('favorite_border', Icons.favorite_border, 'Amour divin', ['amour', 'charité', 'compassion', 'cœur']),
      IconOption('emoji_emotions', Icons.emoji_emotions, 'Joie du Seigneur', ['joie', 'allégresse', 'bonheur', 'célébration']),
      IconOption('groups_2', Icons.groups_2, 'Corps du Christ', ['église', 'corps', 'unité', 'communauté']),
      IconOption('support', Icons.support, 'Soutien spirituel', ['soutien', 'aide', 'encouragement', 'accompagnement']),
      IconOption('hub', Icons.hub, 'Centre spirituel', ['centre', 'focal', 'rassemblement', 'unité']),
      IconOption('landscape', Icons.landscape, 'Création divine', ['création', 'nature', 'beauté', 'œuvre']),
      IconOption('emoji_nature', Icons.emoji_nature, 'Bénédiction naturelle', ['nature', 'bénédiction', 'création', 'vie']),
      IconOption('psychology_alt', Icons.psychology_alt, 'Discernement', ['discernement', 'sagesse', 'intelligence', 'esprit']),
      IconOption('connect_without_contact', Icons.connect_without_contact, 'Union spirituelle', ['union', 'connexion', 'harmonie', 'unité']),
      IconOption('coronavirus', Icons.coronavirus, 'Protection divine', ['protection', 'garde', 'sécurité', 'abri']),
      IconOption('clean_hands', Icons.clean_hands, 'Pureté', ['pureté', 'sainteté', 'propreté', 'innocence']),
      IconOption('health_and_safety', Icons.health_and_safety, 'Salut', ['salut', 'sécurité', 'protection', 'rédemption']),
      IconOption('volunteer_activism', Icons.volunteer_activism, 'Mission', ['mission', 'service', 'appel', 'œuvre']),

      // Musique et worship
      IconOption('library_music', Icons.library_music, 'Musique', ['chants', 'cantiques', 'louange']),
      IconOption('music_note', Icons.music_note, 'Note musicale', ['mélodie', 'son', 'harmonie']),
      IconOption('queue_music', Icons.queue_music, 'Playlist', ['liste', 'sélection', 'programme']),
      IconOption('piano', Icons.piano, 'Piano', ['instrument', 'clavier', 'accompagnement']),
      IconOption('mic', Icons.mic, 'Microphone', ['voix', 'chant', 'prédication']),
      IconOption('volume_up', Icons.volume_up, 'Son', ['audio', 'haut-parleur', 'diffusion']),
      IconOption('headphones', Icons.headphones, 'Écoute', ['casque', 'audio', 'personnel']),
      IconOption('radio', Icons.radio, 'Radio', ['diffusion', 'émission', 'média']),
      IconOption('surround_sound', Icons.surround_sound, 'Son surround', ['audio', 'qualité', 'immersion']),
      IconOption('graphic_eq', Icons.graphic_eq, 'Égaliseur', ['son', 'audio', 'réglage']),

      // Tâches et gestion
      IconOption('task_alt', Icons.task_alt, 'Tâche', ['travail', 'mission', 'objectif']),
      IconOption('assignment', Icons.assignment, 'Assignement', ['mission', 'devoir', 'responsabilité']),
      IconOption('checklist', Icons.checklist, 'Liste de contrôle', ['vérification', 'validation', 'suivi']),
      IconOption('check_circle', Icons.check_circle, 'Terminé', ['fini', 'accompli', 'validé']),
      IconOption('pending_actions', Icons.pending_actions, 'En attente', ['suspendu', 'reporté', 'différé']),
      IconOption('work', Icons.work, 'Travail', ['emploi', 'tâche', 'fonction']),
      IconOption('business_center', Icons.business_center, 'Affaires', ['professionnel', 'entreprise', 'commerce']),
      IconOption('folder_open', Icons.folder_open, 'Dossier ouvert', ['fichiers', 'documents', 'archives']),
      IconOption('description', Icons.description, 'Description', ['document', 'texte', 'note']),
      IconOption('list_alt', Icons.list_alt, 'Liste', ['énumération', 'inventaire', 'catalogue']),

      // Communication et notifications
      IconOption('notifications', Icons.notifications, 'Notifications', ['alertes', 'messages', 'avis']),
      IconOption('message', Icons.message, 'Message', ['texto', 'communication', 'discussion']),
      IconOption('chat', Icons.chat, 'Chat', ['conversation', 'dialogue', 'échange']),
      IconOption('email', Icons.email, 'Email', ['courrier', 'message', 'communication']),
      IconOption('phone', Icons.phone, 'Téléphone', ['appel', 'contact', 'communication']),
      IconOption('forum', Icons.forum, 'Forum', ['discussion', 'débat', 'échange']),
      IconOption('campaign', Icons.campaign, 'Campagne', ['annonce', 'publication', 'diffusion']),
      IconOption('announcement', Icons.announcement, 'Annonce', ['information', 'nouvelle', 'avis']),
      IconOption('speaker_notes', Icons.speaker_notes, 'Notes orateur', ['prédication', 'présentation', 'discours']),
      IconOption('record_voice_over', Icons.record_voice_over, 'Enregistrement vocal', ['prédication', 'témoignage', 'message']),

      // Navigation et interface
      IconOption('dashboard', Icons.dashboard, 'Tableau de bord', ['accueil', 'résumé', 'vue d\'ensemble']),
      IconOption('home', Icons.home, 'Accueil', ['maison', 'début', 'principal']),
      IconOption('menu', Icons.menu, 'Menu', ['navigation', 'options', 'choix']),
      IconOption('apps', Icons.apps, 'Applications', ['modules', 'fonctions', 'outils']),
      IconOption('widgets', Icons.widgets, 'Widgets', ['composants', 'éléments', 'blocs']),
      IconOption('view_module', Icons.view_module, 'Vue modules', ['affichage', 'organisation', 'structure']),
      IconOption('grid_view', Icons.grid_view, 'Vue grille', ['mosaïque', 'tableau', 'organisation']),
      IconOption('list', Icons.list, 'Liste', ['énumération', 'série', 'suite']),
      IconOption('view_list', Icons.view_list, 'Vue liste', ['affichage', 'linéaire', 'vertical']),
      IconOption('table_view', Icons.table_view, 'Vue tableau', ['grille', 'données', 'organisation']),

      // Paramètres et configuration
      IconOption('settings', Icons.settings, 'Paramètres', ['configuration', 'réglages', 'options']),
      IconOption('tune', Icons.tune, 'Réglages', ['ajustements', 'personnalisation', 'adaptation']),
      IconOption('build', Icons.build, 'Outils', ['construction', 'maintenance', 'réparation']),
      IconOption('engineering', Icons.engineering, 'Ingénierie', ['technique', 'développement', 'conception']),
      IconOption('admin_panel_settings', Icons.admin_panel_settings, 'Administration', ['gestion', 'contrôle', 'supervision']),
      IconOption('security', Icons.security, 'Sécurité', ['protection', 'confidentialité', 'sûreté']),
      IconOption('lock', Icons.lock, 'Verrouillage', ['sécurité', 'protection', 'accès']),
      IconOption('key', Icons.key, 'Clé', ['accès', 'autorisation', 'ouverture']),
      IconOption('vpn_key', Icons.vpn_key, 'Clé VPN', ['sécurité', 'cryptage', 'protection']),
      IconOption('password', Icons.password, 'Mot de passe', ['sécurité', 'authentification', 'accès']),

      // Médias et contenu
      IconOption('photo_library', Icons.photo_library, 'Photothèque', ['images', 'galerie', 'collection']),
      IconOption('video_library', Icons.video_library, 'Vidéothèque', ['films', 'enregistrements', 'archives']),
      IconOption('play_circle', Icons.play_circle, 'Lecture', ['démarrer', 'jouer', 'commencer']),
      IconOption('pause_circle', Icons.pause_circle, 'Pause', ['arrêt', 'suspension', 'interruption']),
      IconOption('stop_circle', Icons.stop_circle, 'Arrêt', ['fin', 'terminer', 'stopper']),
      IconOption('movie', Icons.movie, 'Film', ['cinéma', 'vidéo', 'enregistrement']),
      IconOption('camera_alt', Icons.camera_alt, 'Appareil photo', ['capture', 'photographie', 'image']),
      IconOption('videocam', Icons.videocam, 'Caméra', ['enregistrement', 'film', 'captation']),
      IconOption('photo_camera', Icons.photo_camera, 'Photo', ['image', 'capture', 'souvenir']),
      IconOption('perm_media', Icons.perm_media, 'Médias', ['contenu', 'fichiers', 'ressources']),

      // Finance et dons
      IconOption('attach_money', Icons.attach_money, 'Argent', ['finances', 'dons', 'offrandes']),
      IconOption('payment', Icons.payment, 'Paiement', ['transaction', 'règlement', 'versement']),
      IconOption('account_balance', Icons.account_balance, 'Banque', ['finances', 'compte', 'trésorerie']),
      IconOption('savings', Icons.savings, 'Épargne', ['économies', 'réserves', 'fonds']),
      IconOption('monetization_on', Icons.monetization_on, 'Monétisation', ['revenus', 'gains', 'bénéfices']),
      IconOption('volunteer_activism', Icons.volunteer_activism, 'Don', ['offrande', 'contribution', 'générosité']),
      IconOption('card_giftcard', Icons.card_giftcard, 'Carte cadeau', ['présent', 'don', 'surprise']),
      IconOption('redeem', Icons.redeem, 'Échange', ['cadeau', 'récompense', 'bonus']),
      IconOption('receipt', Icons.receipt, 'Reçu', ['facture', 'ticket', 'justificatif']),
      IconOption('request_quote', Icons.request_quote, 'Devis', ['estimation', 'cotation', 'prix']),

      // Transport et localisation
      IconOption('location_on', Icons.location_on, 'Localisation', ['adresse', 'lieu', 'position']),
      IconOption('map', Icons.map, 'Carte', ['plan', 'navigation', 'géographie']),
      IconOption('directions', Icons.directions, 'Directions', ['itinéraire', 'chemin', 'route']),
      IconOption('place', Icons.place, 'Lieu', ['endroit', 'position', 'site']),
      IconOption('room', Icons.room, 'Salle', ['pièce', 'espace', 'local']),
      IconOption('business', Icons.business, 'Entreprise', ['bureau', 'société', 'organisation']),
      IconOption('store', Icons.store, 'Magasin', ['boutique', 'commerce', 'vente']),
      IconOption('local_shipping', Icons.local_shipping, 'Livraison', ['transport', 'expédition', 'envoi']),
      IconOption('flight', Icons.flight, 'Vol', ['avion', 'voyage', 'déplacement']),
      IconOption('directions_car', Icons.directions_car, 'Voiture', ['automobile', 'transport', 'véhicule']),

      // Santé et bien-être
      IconOption('health_and_safety', Icons.health_and_safety, 'Santé et sécurité', ['bien-être', 'protection', 'soin']),
      IconOption('local_hospital', Icons.local_hospital, 'Hôpital', ['médical', 'soin', 'urgence']),
      IconOption('healing', Icons.healing, 'Guérison', ['soin', 'rétablissement', 'thérapie']),
      IconOption('self_improvement', Icons.self_improvement, 'Amélioration personnelle', ['développement', 'croissance', 'spiritualité']),
      IconOption('psychology', Icons.psychology, 'Psychologie', ['mental', 'esprit', 'bien-être']),
      IconOption('spa', Icons.spa, 'Détente', ['relaxation', 'bien-être', 'sérénité']),
      IconOption('fitness_center', Icons.fitness_center, 'Fitness', ['exercice', 'sport', 'santé']),
      IconOption('emoji_nature', Icons.emoji_nature, 'Nature', ['environnement', 'écologie', 'création']),
      IconOption('local_florist', Icons.local_florist, 'Fleuriste', ['fleurs', 'beauté', 'nature']),
      IconOption('park', Icons.park, 'Parc', ['nature', 'espace vert', 'détente']),

      // Éducation et formation
      IconOption('school', Icons.school, 'École', ['éducation', 'formation', 'apprentissage']),
      IconOption('classroom', Icons.school, 'Classe', ['cours', 'enseignement', 'leçon']),
      IconOption('menu_book', Icons.menu_book, 'Manuel', ['livre', 'guide', 'référence']),
      IconOption('quiz', Icons.quiz, 'Quiz', ['test', 'évaluation', 'questionnaire']),
      IconOption('science', Icons.science, 'Science', ['recherche', 'expérience', 'découverte']),
      IconOption('psychology', Icons.psychology, 'Étude', ['apprentissage', 'recherche', 'analyse']),
      IconOption('lightbulb', Icons.lightbulb, 'Idée', ['innovation', 'créativité', 'inspiration']),
      IconOption('tips_and_updates', Icons.tips_and_updates, 'Conseils', ['aide', 'suggestions', 'amélioration']),
      IconOption('help', Icons.help, 'Aide', ['assistance', 'support', 'question']),
      IconOption('info', Icons.info, 'Information', ['détails', 'explication', 'renseignement']),

      // Technologie et digital
      IconOption('computer', Icons.computer, 'Ordinateur', ['technologie', 'digital', 'informatique']),
      IconOption('smartphone', Icons.smartphone, 'Smartphone', ['mobile', 'téléphone', 'portable']),
      IconOption('tablet', Icons.tablet, 'Tablette', ['écran', 'mobile', 'portable']),
      IconOption('web', Icons.web, 'Web', ['internet', 'site', 'navigation']),
      IconOption('wifi', Icons.wifi, 'WiFi', ['connexion', 'réseau', 'internet']),
      IconOption('cloud', Icons.cloud, 'Cloud', ['nuage', 'stockage', 'sauvegarde']),
      IconOption('backup', Icons.backup, 'Sauvegarde', ['copie', 'archivage', 'protection']),
      IconOption('download', Icons.download, 'Télécharger', ['récupérer', 'obtenir', 'importer']),
      IconOption('upload', Icons.upload, 'Envoyer', ['téléverser', 'partager', 'exporter']),
      IconOption('sync', Icons.sync, 'Synchroniser', ['actualiser', 'mettre à jour', 'harmoniser']),

      // Divers et utilitaires
      IconOption('star', Icons.star, 'Étoile', ['favori', 'important', 'excellence']),
      IconOption('bookmark', Icons.bookmark, 'Marque-page', ['favori', 'sauvegarde', 'référence']),
      IconOption('flag', Icons.flag, 'Drapeau', ['marqueur', 'signal', 'priorité']),
      IconOption('label', Icons.label, 'Étiquette', ['tag', 'catégorie', 'classification']),
      IconOption('new_releases', Icons.new_releases, 'Nouveauté', ['récent', 'actualité', 'innovation']),
      IconOption('trending_up', Icons.trending_up, 'Tendance montante', ['croissance', 'amélioration', 'succès']),
      IconOption('trending_down', Icons.trending_down, 'Tendance descendante', ['déclin', 'baisse', 'réduction']),
      IconOption('insights', Icons.insights, 'Analyses', ['statistiques', 'données', 'rapport']),
      IconOption('analytics', Icons.analytics, 'Analytiques', ['mesures', 'métriques', 'performance']),
      IconOption('assessment', Icons.assessment, 'Évaluation', ['analyse', 'mesure', 'bilan']),
    ];
  }
}

/// Modèle pour une option d'icône
class IconOption {
  final String name;
  final IconData iconData;
  final String description;
  final List<String> keywords;

  IconOption(this.name, this.iconData, this.description, this.keywords);
}
