import 'package:cloud_firestore/cloud_firestore.dart';
import 'tache_processus_model.dart';

/// Modèle pour les départements/ministères de l'église
class DepartementEglise {
  final String id;
  final String nom;
  final String description;
  final String? responsableId;
  final String? responsableNom;
  final List<String> membresIds;
  final List<String> membresNoms;
  final String couleur; // Couleur hex pour l'identification visuelle
  final String icone; // Nom de l'icône Material
  final bool actif;
  final DateTime dateCreation;
  final Map<String, dynamic> metadonnees;

  DepartementEglise({
    required this.id,
    required this.nom,
    required this.description,
    this.responsableId,
    this.responsableNom,
    this.membresIds = const [],
    this.membresNoms = const [],
    this.couleur = '#2196F3',
    this.icone = 'groups',
    this.actif = true,
    required this.dateCreation,
    this.metadonnees = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'responsableId': responsableId,
      'responsableNom': responsableNom,
      'membresIds': membresIds,
      'membresNoms': membresNoms,
      'couleur': couleur,
      'icone': icone,
      'actif': actif,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'metadonnees': metadonnees,
    };
  }

  factory DepartementEglise.fromMap(Map<String, dynamic> map) {
    return DepartementEglise(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      responsableId: map['responsableId'],
      responsableNom: map['responsableNom'],
      membresIds: List<String>.from(map['membresIds'] ?? []),
      membresNoms: List<String>.from(map['membresNoms'] ?? []),
      couleur: map['couleur'] ?? '#2196F3',
      icone: map['icone'] ?? 'groups',
      actif: map['actif'] ?? true,
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadonnees: Map<String, dynamic>.from(map['metadonnees'] ?? {}),
    );
  }

  factory DepartementEglise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return DepartementEglise.fromMap(data);
  }
}

/// Modèle pour les processus de l'église (extension du modèle existant)
class ProcessusEglise {
  final String id;
  final String nom;
  final String description;
  final String? departementId;
  final String? departementNom;
  final String? responsableId;
  final String? responsableNom;
  final List<String> collaborateursIds;
  final List<String> collaborateursNoms;
  
  // Planification
  final String frequence; // 'quotidien', 'hebdomadaire', 'mensuel', 'ponctuel'
  final Map<String, dynamic> configFrequence;
  final DateTime? prochaineDateExecution;
  
  // Statut et progression
  final bool actif;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String createurId;
  
  // Métriques
  final int nombreTachesTotales;
  final int nombreTachesCompletes;
  final double tauxCompletion;
  final Duration tempsMoyenExecution;
  
  // Configuration
  final List<String> tags;
  final Map<String, dynamic> metadonnees;

  ProcessusEglise({
    required this.id,
    required this.nom,
    required this.description,
    this.departementId,
    this.departementNom,
    this.responsableId,
    this.responsableNom,
    this.collaborateursIds = const [],
    this.collaborateursNoms = const [],
    this.frequence = 'hebdomadaire',
    this.configFrequence = const {},
    this.prochaineDateExecution,
    this.actif = true,
    required this.dateCreation,
    required this.dateModification,
    required this.createurId,
    this.nombreTachesTotales = 0,
    this.nombreTachesCompletes = 0,
    this.tauxCompletion = 0.0,
    this.tempsMoyenExecution = Duration.zero,
    this.notificationsActives = true,
    this.parametresNotifications = const {},
    this.tags = const [],
    this.metadonnees = const {},
  });

  bool get estEnRetard => prochaineDateExecution != null && 
      DateTime.now().isAfter(prochaineDateExecution!) && 
      tauxCompletion < 100.0;

  bool get estEnCours => nombreTachesCompletes > 0 && tauxCompletion < 100.0;

  bool get estComplete => tauxCompletion >= 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'departementId': departementId,
      'departementNom': departementNom,
      'responsableId': responsableId,
      'responsableNom': responsableNom,
      'collaborateursIds': collaborateursIds,
      'collaborateursNoms': collaborateursNoms,
      'frequence': frequence,
      'configFrequence': configFrequence,
      'prochaineDateExecution': prochaineDateExecution != null 
          ? Timestamp.fromDate(prochaineDateExecution!) : null,
      'actif': actif,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
      'createurId': createurId,
      'nombreTachesTotales': nombreTachesTotales,
      'nombreTachesCompletes': nombreTachesCompletes,
      'tauxCompletion': tauxCompletion,
      'tempsMoyenExecution': tempsMoyenExecution.inMinutes,
      'notificationsActives': notificationsActives,
      'parametresNotifications': parametresNotifications,
      'tags': tags,
      'metadonnees': metadonnees,
    };
  }

  factory ProcessusEglise.fromMap(Map<String, dynamic> map) {
    return ProcessusEglise(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      departementId: map['departementId'],
      departementNom: map['departementNom'],
      responsableId: map['responsableId'],
      responsableNom: map['responsableNom'],
      collaborateursIds: List<String>.from(map['collaborateursIds'] ?? []),
      collaborateursNoms: List<String>.from(map['collaborateursNoms'] ?? []),
      frequence: map['frequence'] ?? 'hebdomadaire',
      configFrequence: Map<String, dynamic>.from(map['configFrequence'] ?? {}),
      prochaineDateExecution: (map['prochaineDateExecution'] as Timestamp?)?.toDate(),
      actif: map['actif'] ?? true,
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (map['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createurId: map['createurId'] ?? '',
      nombreTachesTotales: map['nombreTachesTotales'] ?? 0,
      nombreTachesCompletes: map['nombreTachesCompletes'] ?? 0,
      tauxCompletion: (map['tauxCompletion'] ?? 0.0).toDouble(),
      tempsMoyenExecution: Duration(minutes: map['tempsMoyenExecution'] ?? 0),
      notificationsActives: map['notificationsActives'] ?? true,
      parametresNotifications: Map<String, dynamic>.from(map['parametresNotifications'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      metadonnees: Map<String, dynamic>.from(map['metadonnees'] ?? {}),
    );
  }

  factory ProcessusEglise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ProcessusEglise.fromMap(data);
  }

  ProcessusEglise copyWith({
    String? nom,
    String? description,
    String? departementId,
    String? departementNom,
    String? responsableId,
    String? responsableNom,
    List<String>? collaborateursIds,
    List<String>? collaborateursNoms,
    String? frequence,
    Map<String, dynamic>? configFrequence,
    DateTime? prochaineDateExecution,
    bool? actif,
    DateTime? dateModification,
    int? nombreTachesTotales,
    int? nombreTachesCompletes,
    double? tauxCompletion,
    Duration? tempsMoyenExecution,
    bool? notificationsActives,
    Map<String, dynamic>? parametresNotifications,
    List<String>? tags,
    Map<String, dynamic>? metadonnees,
  }) {
    return ProcessusEglise(
      id: id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      departementId: departementId ?? this.departementId,
      departementNom: departementNom ?? this.departementNom,
      responsableId: responsableId ?? this.responsableId,
      responsableNom: responsableNom ?? this.responsableNom,
      collaborateursIds: collaborateursIds ?? this.collaborateursIds,
      collaborateursNoms: collaborateursNoms ?? this.collaborateursNoms,
      frequence: frequence ?? this.frequence,
      configFrequence: configFrequence ?? this.configFrequence,
      prochaineDateExecution: prochaineDateExecution ?? this.prochaineDateExecution,
      actif: actif ?? this.actif,
      dateCreation: dateCreation,
      dateModification: dateModification ?? DateTime.now(),
      createurId: createurId,
      nombreTachesTotales: nombreTachesTotales ?? this.nombreTachesTotales,
      nombreTachesCompletes: nombreTachesCompletes ?? this.nombreTachesCompletes,
      tauxCompletion: tauxCompletion ?? this.tauxCompletion,
      tempsMoyenExecution: tempsMoyenExecution ?? this.tempsMoyenExecution,
      notificationsActives: notificationsActives ?? this.notificationsActives,
      parametresNotifications: parametresNotifications ?? this.parametresNotifications,
      tags: tags ?? this.tags,
      metadonnees: metadonnees ?? this.metadonnees,
    );
  }
}

/// Modèle pour les statistiques de processus
class StatistiquesProcessus {
  final String processusId;
  final DateTime periode;
  final int nombreTachesCreees;
  final int nombreTachesCompletes;
  final int nombreTachesEnRetard;
  final double tauxCompletion;
  final double tauxPonctualite;
  final Duration tempsMoyenExecution;
  final Map<StatutTache, int> repartitionStatuts;
  final Map<PrioriteTache, int> repartitionPriorites;
  final Map<String, int> repartitionResponsables;

  StatistiquesProcessus({
    required this.processusId,
    required this.periode,
    this.nombreTachesCreees = 0,
    this.nombreTachesCompletes = 0,
    this.nombreTachesEnRetard = 0,
    this.tauxCompletion = 0.0,
    this.tauxPonctualite = 0.0,
    this.tempsMoyenExecution = Duration.zero,
    this.repartitionStatuts = const {},
    this.repartitionPriorites = const {},
    this.repartitionResponsables = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'processusId': processusId,
      'periode': Timestamp.fromDate(periode),
      'nombreTachesCreees': nombreTachesCreees,
      'nombreTachesCompletes': nombreTachesCompletes,
      'nombreTachesEnRetard': nombreTachesEnRetard,
      'tauxCompletion': tauxCompletion,
      'tauxPonctualite': tauxPonctualite,
      'tempsMoyenExecution': tempsMoyenExecution.inMinutes,
      'repartitionStatuts': repartitionStatuts.map((k, v) => MapEntry(k.value, v)),
      'repartitionPriorites': repartitionPriorites.map((k, v) => MapEntry(k.niveau.toString(), v)),
      'repartitionResponsables': repartitionResponsables,
    };
  }

  factory StatistiquesProcessus.fromMap(Map<String, dynamic> map) {
    return StatistiquesProcessus(
      processusId: map['processusId'] ?? '',
      periode: (map['periode'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nombreTachesCreees: map['nombreTachesCreees'] ?? 0,
      nombreTachesCompletes: map['nombreTachesCompletes'] ?? 0,
      nombreTachesEnRetard: map['nombreTachesEnRetard'] ?? 0,
      tauxCompletion: (map['tauxCompletion'] ?? 0.0).toDouble(),
      tauxPonctualite: (map['tauxPonctualite'] ?? 0.0).toDouble(),
      tempsMoyenExecution: Duration(minutes: map['tempsMoyenExecution'] ?? 0),
      repartitionStatuts: Map<StatutTache, int>.fromEntries(
        (map['repartitionStatuts'] as Map<String, dynamic>? ?? {}).entries.map(
          (e) => MapEntry(
            StatutTache.values.firstWhere((s) => s.value == e.key),
            e.value as int,
          ),
        ),
      ),
      repartitionPriorites: Map<PrioriteTache, int>.fromEntries(
        (map['repartitionPriorites'] as Map<String, dynamic>? ?? {}).entries.map(
          (e) => MapEntry(
            PrioriteTache.values.firstWhere((p) => p.niveau.toString() == e.key),
            e.value as int,
          ),
        ),
      ),
      repartitionResponsables: Map<String, int>.from(map['repartitionResponsables'] ?? {}),
    );
  }
}
