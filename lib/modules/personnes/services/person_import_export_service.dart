import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/person_module_model.dart';
import '../../../services/people_module_service.dart';
import '../../../utils/share_utils.dart';

/// Types de formats d'import/export supportés
enum ExportFormat {
  csv,
  json,
  excel,
}

/// Résultat d'une opération d'import
class ImportResult {
  final bool success;
  final int totalRecords;
  final int importedRecords;
  final int skippedRecords;
  final List<String> errors;
  final String? message;

  ImportResult({
    required this.success,
    required this.totalRecords,
    required this.importedRecords,
    required this.skippedRecords,
    required this.errors,
    this.message,
  });

  double get successRate => totalRecords > 0 ? (importedRecords / totalRecords) * 100 : 0;
}

/// Résultat d'une opération d'export
class ExportResult {
  final bool success;
  final String? filePath;
  final int recordCount;
  final String? message;
  final String? error;

  ExportResult({
    required this.success,
    this.filePath,
    required this.recordCount,
    this.message,
    this.error,
  });
}

/// Configuration pour l'import/export
class ImportExportConfig {
  final bool includeInactive;
  final List<String> includeFields;
  final List<String> excludeFields;
  final Map<String, String> fieldMapping; // mapping ancien nom -> nouveau nom
  final bool validateEmails;
  final bool validatePhones;
  final bool allowDuplicateEmail;
  final bool updateExisting;

  const ImportExportConfig({
    this.includeInactive = false,
    this.includeFields = const [],
    this.excludeFields = const [],
    this.fieldMapping = const {},
    this.validateEmails = true,
    this.validatePhones = true,
    this.allowDuplicateEmail = false,
    this.updateExisting = false,
  });
}

/// Service pour l'import et l'export des personnes
class PersonImportExportService {
  final PeopleModuleService _peopleService = PeopleModuleService();

  /// Champs standard disponibles pour l'export
  static const List<String> standardFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'country',
    'birthDate',
    'gender',
    'maritalStatus',
    'address',
    'additionalAddress',
    'zipCode',
    'city',
    'age',
    'roles',
    'isActive',
    'createdAt',
    'updatedAt',
  ];

  /// Templates de mapping pour différents formats d'import
  static const Map<String, Map<String, String>> importTemplates = {
    'default': {
      'firstName': 'firstName',
      'lastName': 'lastName',
      'email': 'email',
      'phone': 'phone',
      'country': 'country',
      'birthDate': 'birthDate',
      'gender': 'gender',
      'maritalStatus': 'maritalStatus',
      'address': 'address',
      'additionalAddress': 'additionalAddress',
      'zipCode': 'zipCode',
      'city': 'city',
      'roles': 'roles',
    },
    'mailchimp': {
      'FNAME': 'firstName',
      'LNAME': 'lastName',
      'EMAIL': 'email',
      'PHONE': 'phone',
      'ADDRESS': 'address',
      'BIRTHDAY': 'birthDate',
    },
    'google_contacts': {
      'Given Name': 'firstName',
      'Family Name': 'lastName',
      'E-mail Address': 'email',
      'Phone Number': 'phone',
      'Address': 'address',
      'Birthday': 'birthDate',
    },
  };

  // ===========================
  // FONCTIONS D'EXPORT
  // ===========================

  /// Exporter toutes les personnes
  Future<ExportResult> exportAll({
    ExportFormat format = ExportFormat.csv,
    ImportExportConfig config = const ImportExportConfig(),
  }) async {
    try {
      final people = await _peopleService.getAll();
      final filteredPeople = _filterPeopleForExport(people, config);
      
      return await _exportPeople(
        people: filteredPeople,
        format: format,
        config: config,
        filename: 'toutes_les_personnes',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export: $e',
      );
    }
  }

  /// Exporter des personnes sélectionnées
  Future<ExportResult> exportSelected({
    required List<Person> people,
    ExportFormat format = ExportFormat.csv,
    ImportExportConfig config = const ImportExportConfig(),
    String filename = 'personnes_selectionnees',
  }) async {
    try {
      final filteredPeople = _filterPeopleForExport(people, config);
      
      return await _exportPeople(
        people: filteredPeople,
        format: format,
        config: config,
        filename: filename,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export: $e',
      );
    }
  }

  /// Exporter des personnes par critère
  Future<ExportResult> exportByCriteria({
    String? role,
    List<String>? tags,
    DateTimeRange? birthDateRange,
    bool? isActive,
    ExportFormat format = ExportFormat.csv,
    ImportExportConfig config = const ImportExportConfig(),
  }) async {
    try {
      List<Person> people = await _peopleService.getAll();

      // Filtrer par critères
      if (role != null) {
        people = people.where((p) => p.hasRole(role)).toList();
      }
      
      if (tags != null && tags.isNotEmpty) {
        people = people.where((p) => 
          tags.any((tag) => p.roles.contains(tag))
        ).toList();
      }

      if (birthDateRange != null) {
        people = people.where((p) => 
          p.birthDate != null &&
          p.birthDate!.isAfter(birthDateRange.start) &&
          p.birthDate!.isBefore(birthDateRange.end)
        ).toList();
      }

      if (isActive != null) {
        people = people.where((p) => p.isActive == isActive).toList();
      }

      final filteredPeople = _filterPeopleForExport(people, config);
      
      return await _exportPeople(
        people: filteredPeople,
        format: format,
        config: config,
        filename: 'personnes_filtrees',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export par critères: $e',
      );
    }
  }

  /// Export principal
  Future<ExportResult> _exportPeople({
    required List<Person> people,
    required ExportFormat format,
    required ImportExportConfig config,
    required String filename,
  }) async {
    try {
      switch (format) {
        case ExportFormat.csv:
          return await _exportToCsv(people, config, filename);
        case ExportFormat.json:
          return await _exportToJson(people, config, filename);
        case ExportFormat.excel:
          return await _exportToExcel(people, config, filename);
      }
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export: $e',
      );
    }
  }

  /// Export vers CSV
  Future<ExportResult> _exportToCsv(
    List<Person> people,
    ImportExportConfig config,
    String filename,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final headers = _getExportHeaders(config);
      final rows = <List<String>>[];
      
      // Ajouter les en-têtes
      rows.add(headers);
      
      // Ajouter les données
      for (final person in people) {
        final row = _personToRow(person, headers, config);
        rows.add(row);
      }
      
      final csvData = const ListToCsvConverter().convert(rows);
      final file = File(filePath);
      await file.writeAsString(csvData, encoding: utf8);
      
      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: people.length,
        message: 'Export CSV réussi: ${people.length} personnes exportées',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export CSV: $e',
      );
    }
  }

  /// Export vers JSON
  Future<ExportResult> _exportToJson(
    List<Person> people,
    ImportExportConfig config,
    String filename,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': people.length,
        'config': {
          'includeInactive': config.includeInactive,
          'includeFields': config.includeFields,
          'excludeFields': config.excludeFields,
        },
        'people': people.map((person) => _personToMap(person, config)).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8);
      
      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: people.length,
        message: 'Export JSON réussi: ${people.length} personnes exportées',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export JSON: $e',
      );
    }
  }

  /// Export vers Excel (.xlsx)
  Future<ExportResult> _exportToExcel(
    List<Person> people,
    ImportExportConfig config,
    String filename,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      // Créer un nouveau fichier Excel
      final excel = Excel.createExcel();
      final sheet = excel['Personnes'];
      
      // Supprimer la feuille par défaut si elle existe
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
      
      // Obtenir les en-têtes
      final headers = _getExportHeaders(config);
      
      // Ajouter les en-têtes
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        
        // Style pour les en-têtes
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue100,
          fontColorHex: ExcelColor.black,
        );
      }
      
      // Ajouter les données
      for (int row = 0; row < people.length; row++) {
        final person = people[row];
        final rowData = _personToRow(person, headers, config);
        
        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          final value = rowData[col];
          
          // Déterminer le type de données et formater en conséquence
          if (value.isEmpty) {
            cell.value = TextCellValue('');
          } else if (RegExp(r'^\d+$').hasMatch(value)) {
            // Nombre entier
            cell.value = IntCellValue(int.tryParse(value) ?? 0);
          } else if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
            // Nombre décimal
            cell.value = DoubleCellValue(double.tryParse(value) ?? 0.0);
          } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
            // Date ISO
            try {
              final date = DateTime.parse(value);
              cell.value = DateCellValue(
                year: date.year,
                month: date.month,
                day: date.day,
              );
            } catch (e) {
              cell.value = TextCellValue(value);
            }
          } else if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
            // Booléen
            cell.value = BoolCellValue(value.toLowerCase() == 'true');
          } else {
            // Texte par défaut
            cell.value = TextCellValue(value);
          }
        }
      }
      
      // Ajuster automatiquement la largeur des colonnes
      for (int col = 0; col < headers.length; col++) {
        sheet.setColumnAutoFit(col);
      }
      
      // Sauvegarder le fichier
      final file = File(filePath);
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }
      
      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: people.length,
        message: 'Export Excel réussi: ${people.length} personnes exportées',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: 0,
        error: 'Erreur lors de l\'export Excel: $e',
      );
    }
  }

  // ===========================
  // FONCTIONS D'IMPORT
  // ===========================


  /// Importer depuis un fichier
  Future<ImportResult> importFromFile({
    ImportExportConfig config = const ImportExportConfig(),
    String? templateName,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'txt', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Aucun fichier sélectionné'],
        );
      }

      final file = File(result.files.first.path!);
      final extension = result.files.first.extension?.toLowerCase();

      switch (extension) {
        case 'csv':
        case 'txt':
          return await _importFromCsv(file, config, templateName);
        case 'json':
          return await _importFromJson(file, config);
        case 'xlsx':
        case 'xls':
          return await _importFromExcel(file, config, templateName);
        default:
          return ImportResult(
            success: false,
            totalRecords: 0,
            importedRecords: 0,
            skippedRecords: 0,
            errors: ['Format de fichier non supporté: $extension'],
          );
      }
    } catch (e) {
      return ImportResult(
        success: false,
        totalRecords: 0,
        importedRecords: 0,
        skippedRecords: 0,
        errors: ['Erreur lors de l\'import: $e'],
      );
    }
  }

  /// Import depuis CSV
  Future<ImportResult> _importFromCsv(
    File file,
    ImportExportConfig config,
    String? templateName,
  ) async {
    try {
      final content = await file.readAsString(encoding: utf8);
      final rows = const CsvToListConverter().convert(content);
      
      if (rows.isEmpty) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Fichier vide'],
        );
      }

      final headers = rows.first.map((e) => e.toString()).toList();
      final dataRows = rows.skip(1).toList();
      
      // Obtenir le mapping des champs
      final mapping = _getFieldMapping(headers, config, templateName);
      
      final errors = <String>[];
      int importedCount = 0;
      int skippedCount = 0;

      for (int i = 0; i < dataRows.length; i++) {
        try {
          final row = dataRows[i];
          final person = await _rowToPerson(row, headers, mapping, config);
          
          if (person != null) {
            final success = await _savePerson(person, config);
            if (success) {
              importedCount++;
            } else {
              skippedCount++;
              errors.add('Ligne ${i + 2}: Erreur lors de la sauvegarde');
            }
          } else {
            skippedCount++;
            errors.add('Ligne ${i + 2}: Données invalides');
          }
        } catch (e) {
          skippedCount++;
          errors.add('Ligne ${i + 2}: $e');
        }
      }

      return ImportResult(
        success: importedCount > 0,
        totalRecords: dataRows.length,
        importedRecords: importedCount,
        skippedRecords: skippedCount,
        errors: errors,
        message: '$importedCount personnes importées, $skippedCount ignorées',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        totalRecords: 0,
        importedRecords: 0,
        skippedRecords: 0,
        errors: ['Erreur lors de l\'import CSV: $e'],
      );
    }
  }

  /// Import depuis JSON
  Future<ImportResult> _importFromJson(
    File file,
    ImportExportConfig config,
  ) async {
    try {
      final content = await file.readAsString(encoding: utf8);
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      final peopleData = data['people'] as List<dynamic>?;
      if (peopleData == null) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Format JSON invalide: clé "people" manquante'],
        );
      }

      final errors = <String>[];
      int importedCount = 0;
      int skippedCount = 0;

      for (int i = 0; i < peopleData.length; i++) {
        try {
          final personData = peopleData[i] as Map<String, dynamic>;
          final person = _mapToPerson(personData, config);
          
          if (person != null) {
            final success = await _savePerson(person, config);
            if (success) {
              importedCount++;
            } else {
              skippedCount++;
              errors.add('Personne ${i + 1}: Erreur lors de la sauvegarde');
            }
          } else {
            skippedCount++;
            errors.add('Personne ${i + 1}: Données invalides');
          }
        } catch (e) {
          skippedCount++;
          errors.add('Personne ${i + 1}: $e');
        }
      }

      return ImportResult(
        success: importedCount > 0,
        totalRecords: peopleData.length,
        importedRecords: importedCount,
        skippedRecords: skippedCount,
        errors: errors,
        message: '$importedCount personnes importées, $skippedCount ignorées',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        totalRecords: 0,
        importedRecords: 0,
        skippedRecords: 0,
        errors: ['Erreur lors de l\'import JSON: $e'],
      );
    }
  }

  /// Import depuis Excel (XLSX/XLS)
  Future<ImportResult> _importFromExcel(
    File file,
    ImportExportConfig config,
    String? templateName,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // Prendre la première feuille ou une feuille spécifique
      String? sheetName;
      if (excel.tables.isEmpty) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Fichier Excel vide ou corrompu'],
        );
      }
      
      // Prendre la première feuille disponible
      sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      
      if (sheet == null || sheet.rows.isEmpty) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Feuille Excel vide'],
        );
      }

      // Convertir les données Excel en format CSV-like pour réutiliser la logique existante
      final rows = <List<dynamic>>[];
      
      for (final row in sheet.rows) {
        final rowData = <dynamic>[];
        for (final cell in row) {
          // Extraire la valeur de la cellule Excel
          if (cell?.value != null) {
            if (cell!.value is SharedString) {
              rowData.add((cell.value as SharedString).toString());
            } else if (cell.value is TextCellValue) {
              rowData.add((cell.value as TextCellValue).value);
            } else if (cell.value is IntCellValue) {
              rowData.add((cell.value as IntCellValue).value.toString());
            } else if (cell.value is DoubleCellValue) {
              rowData.add((cell.value as DoubleCellValue).value.toString());
            } else if (cell.value is BoolCellValue) {
              rowData.add((cell.value as BoolCellValue).value.toString());
            } else if (cell.value is DateCellValue) {
              rowData.add((cell.value as DateCellValue).year.toString() + '-' +
                         (cell.value as DateCellValue).month.toString().padLeft(2, '0') + '-' +
                         (cell.value as DateCellValue).day.toString().padLeft(2, '0'));
            } else if (cell.value is TimeCellValue) {
              rowData.add((cell.value as TimeCellValue).hour.toString() + ':' +
                         (cell.value as TimeCellValue).minute.toString().padLeft(2, '0'));
            } else {
              rowData.add(cell.value.toString());
            }
          } else {
            rowData.add('');
          }
        }
        rows.add(rowData);
      }
      
      if (rows.isEmpty) {
        return ImportResult(
          success: false,
          totalRecords: 0,
          importedRecords: 0,
          skippedRecords: 0,
          errors: ['Fichier Excel vide'],
        );
      }

      final headers = rows.first.map((e) => e.toString()).toList();
      final dataRows = rows.skip(1).toList();
      
      // Obtenir le mapping des champs (réutilise la logique CSV)
      final mapping = _getFieldMapping(headers, config, templateName);
      
      final errors = <String>[];
      int importedCount = 0;
      int skippedCount = 0;

      for (int i = 0; i < dataRows.length; i++) {
        try {
          final row = dataRows[i];
          final person = await _rowToPerson(row, headers, mapping, config);
          
          if (person != null) {
            final success = await _savePerson(person, config);
            if (success) {
              importedCount++;
            } else {
              skippedCount++;
              errors.add('Ligne ${i + 2}: Erreur lors de la sauvegarde');
            }
          } else {
            skippedCount++;
            errors.add('Ligne ${i + 2}: Données invalides');
          }
        } catch (e) {
          skippedCount++;
          errors.add('Ligne ${i + 2}: $e');
        }
      }

      return ImportResult(
        success: importedCount > 0,
        totalRecords: dataRows.length,
        importedRecords: importedCount,
        skippedRecords: skippedCount,
        errors: errors,
        message: '$importedCount personnes importées depuis Excel, $skippedCount ignorées',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        totalRecords: 0,
        importedRecords: 0,
        skippedRecords: 0,
        errors: ['Erreur lors de l\'import Excel: $e'],
      );
    }
  }

  // ===========================
  // FONCTIONS UTILITAIRES
  // ===========================

  /// Filtrer les personnes pour l'export
  List<Person> _filterPeopleForExport(List<Person> people, ImportExportConfig config) {
    if (!config.includeInactive) {
      people = people.where((p) => p.isActive).toList();
    }
    return people;
  }

  /// Obtenir les en-têtes pour l'export
  List<String> _getExportHeaders(ImportExportConfig config) {
    List<String> headers = [];
    
    if (config.includeFields.isNotEmpty) {
      headers = config.includeFields;
    } else {
      headers = List.from(standardFields);
    }
    
    if (config.excludeFields.isNotEmpty) {
      headers = headers.where((h) => !config.excludeFields.contains(h)).toList();
    }
    
    return headers;
  }

  /// Convertir une personne en ligne de données
  List<String> _personToRow(Person person, List<String> headers, ImportExportConfig config) {
    final row = <String>[];
    
    for (final header in headers) {
      switch (header) {
        case 'firstName':
          row.add(person.firstName);
          break;
        case 'lastName':
          row.add(person.lastName);
          break;
        case 'email':
          row.add(person.email ?? '');
          break;
        case 'phone':
          row.add(person.phone ?? '');
          break;
        case 'country':
          row.add(person.country ?? '');
          break;
        case 'gender':
          row.add(person.gender ?? '');
          break;
        case 'maritalStatus':
          row.add(person.maritalStatus ?? '');
          break;
        case 'address':
          row.add(person.address ?? '');
          break;
        case 'additionalAddress':
          row.add(person.additionalAddress ?? '');
          break;
        case 'zipCode':
          row.add(person.zipCode ?? '');
          break;
        case 'city':
          row.add(person.city ?? '');
          break;
        case 'birthDate':
          row.add(person.birthDate?.toIso8601String().split('T').first ?? '');
          break;
        case 'age':
          row.add(person.age?.toString() ?? '');
          break;
        case 'roles':
          row.add(person.roles.join(', '));
          break;
        case 'isActive':
          row.add(person.isActive ? 'Oui' : 'Non');
          break;
        case 'createdAt':
          row.add(person.createdAt.toIso8601String().split('T').first);
          break;
        case 'updatedAt':
          row.add(person.updatedAt.toIso8601String().split('T').first);
          break;
        default:
          // Champ personnalisé
          row.add(person.getCustomField<String>(header) ?? '');
          break;
      }
    }
    
    return row;
  }

  /// Convertir une personne en Map pour export JSON avec gestion des Timestamps
  Map<String, dynamic> _personToMap(Person person, ImportExportConfig config) {
    final map = _safePersonToMap(person);
    
    if (config.includeFields.isNotEmpty) {
      final filteredMap = <String, dynamic>{};
      for (final field in config.includeFields) {
        if (map.containsKey(field)) {
          filteredMap[field] = map[field];
        }
      }
      return filteredMap;
    }
    
    if (config.excludeFields.isNotEmpty) {
      for (final field in config.excludeFields) {
        map.remove(field);
      }
    }
    
    return map;
  }

  /// Convertir Person en Map en gérant les types Firestore (Timestamp, etc.)
  Map<String, dynamic> _safePersonToMap(Person person) {
    return {
      'id': person.id,
      'firstName': person.firstName,
      'lastName': person.lastName,
      'email': person.email,
      'phone': person.phone,
      'birthDate': person.birthDate?.toIso8601String(),
      'address': person.address,
      'profileImageUrl': person.profileImageUrl,
      'roles': person.roles,
      'customFields': _convertCustomFields(person.customFields),
      'createdAt': person.createdAt.toIso8601String(),
      'updatedAt': person.updatedAt.toIso8601String(),
      'isActive': person.isActive,
    };
  }

  /// Convertir les champs personnalisés en gérant les types Firestore
  Map<String, dynamic> _convertCustomFields(Map<String, dynamic> customFields) {
    final Map<String, dynamic> converted = {};
    
    for (final entry in customFields.entries) {
      final value = entry.value;
      
      if (value is Timestamp) {
        converted[entry.key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        converted[entry.key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        converted[entry.key] = _convertNestedMap(value);
      } else if (value is List) {
        converted[entry.key] = _convertList(value);
      } else {
        converted[entry.key] = value;
      }
    }
    
    return converted;
  }

  /// Convertir une Map imbriquée en gérant les types Firestore
  Map<String, dynamic> _convertNestedMap(Map<String, dynamic> map) {
    final Map<String, dynamic> converted = {};
    
    for (final entry in map.entries) {
      final value = entry.value;
      
      if (value is Timestamp) {
        converted[entry.key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        converted[entry.key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        converted[entry.key] = _convertNestedMap(value);
      } else if (value is List) {
        converted[entry.key] = _convertList(value);
      } else {
        converted[entry.key] = value;
      }
    }
    
    return converted;
  }

  /// Convertir une List en gérant les types Firestore
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Timestamp) {
        return item.toDate().toIso8601String();
      } else if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map<String, dynamic>) {
        return _convertNestedMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Obtenir le mapping intelligent des champs avec détection automatique robuste
  Map<String, String> _getFieldMapping(
    List<String> headers,
    ImportExportConfig config,
    String? templateName,
  ) {
    Map<String, String> mapping = {};
    
    // Utiliser le template si spécifié
    if (templateName != null && importTemplates.containsKey(templateName)) {
      mapping = Map.from(importTemplates[templateName]!);
    }
    
    // Appliquer le mapping personnalisé en priorité
    mapping.addAll(config.fieldMapping);
    
    // Mappings spécifiques pour les variantes orthographiques communes
    final commonVariants = {
      'adress': 'address',
      'additionnalAddress': 'additionalAddress',
      'additionnalAdress': 'additionalAddress',
      'additionnal_address': 'additionalAddress',
      'complement_adress': 'additionalAddress',
      'zipcode': 'zipCode',
      'zip_code': 'zipCode',
    };
    
    // Appliquer les variantes communes si elles ne sont pas déjà mappées
    for (final header in headers) {
      if (!mapping.containsKey(header) && commonVariants.containsKey(header.toLowerCase())) {
        mapping[header] = commonVariants[header.toLowerCase()]!;
      }
    }
    
    // Système de détection automatique intelligent (en dernier recours)
    for (final header in headers) {
      if (!mapping.containsKey(header)) {
        final mappedField = _detectFieldType(header);
        if (mappedField != null) {
          mapping[header] = mappedField;
        }
      }
    }
    
    return mapping;
  }
  
  /// Détection intelligente du type de champ basée sur le nom de colonne
  String? _detectFieldType(String header) {
    final cleanHeader = _cleanHeaderName(header);
    
    // Dictionnaire de correspondances avec variations linguistiques et formats
    final fieldPatterns = {
      'firstName': [
        'prenom', 'prénom', 'firstname', 'first_name', 'first name', 'fname',
        'nom_prenom', 'nom de famille', 'givenname', 'given_name', 'forename'
      ],
      'lastName': [
        'nom', 'lastname', 'last_name', 'last name', 'lname', 'surname',
        'nom_famille', 'nom de famille', 'family_name', 'familyname'
      ],
      'email': [
        'email', 'e-mail', 'e_mail', 'mail', 'courriel', 'adresse_mail',
        'adresse_email', 'email_address', 'contact_email', 'courrier_electronique'
      ],
      'phone': [
        'telephone', 'téléphone', 'phone', 'tel', 'mobile', 'portable',
        'phone_number', 'telephone_number', 'numero_telephone', 'num_tel',
        'contact_phone', 'cellulaire', 'gsm'
      ],
      'country': [
        'country', 'pays', 'nation', 'nationalite', 'nationalité', 'origine',
        'country_code', 'pays_origine', 'land'
      ],
      'gender': [
        'genre', 'gender', 'sexe', 'sex', 'masculin', 'feminin', 'féminin',
        'male', 'female', 'homme', 'femme'
      ],
      'maritalStatus': [
        'maritalstatus', 'marital_status', 'statut_marital', 'statut_matrimonial',
        'etat_civil', 'état_civil', 'marie', 'marié', 'celibataire', 'célibataire',
        'married', 'single', 'divorced', 'veuf', 'veuve', 'widow'
      ],
      'address': [
        'adresse', 'address', 'rue', 'street', 'domicile', 'residence',
        'full_address', 'adresse_complete', 'lieu', 'location', 'adresse_principale'
      ],
      'additionalAddress': [
        'additionaladdress', 'additional_address', 'adresse_complementaire',
        'complement_adresse', 'adresse_2', 'address_2', 'suite', 'appartement',
        'apt', 'etage', 'étage', 'batiment', 'bâtiment', 'additionnaladdress',
        'additionnal_address', 'adress_2', 'complement_adress'
      ],
      'zipCode': [
        'zipcode', 'zip_code', 'zip', 'code_postal', 'postal_code', 'cp',
        'postcode', 'postal'
      ],
      'city': [
        'city', 'ville', 'town', 'commune', 'locality', 'localite', 'localité',
        'municipality', 'municipalite', 'municipalité'
      ],
      'birthDate': [
        'naissance', 'date_naissance', 'birthdate', 'birth_date', 'birth date',
        'dateofbirth', 'date_of_birth', 'dob', 'anniversaire', 'birthday',
        'date_anniversaire'
      ],
      'roles': [
        'role', 'roles', 'fonction', 'fonctions', 'position', 'positions',
        'titre', 'titres', 'responsabilite', 'responsabilités', 'ministry',
        'ministere', 'ministère', 'service', 'services'
      ],
      'isActive': [
        'actif', 'active', 'is_active', 'statut', 'status', 'etat', 'état',
        'enabled', 'disabled', 'valide', 'valid'
      ]
    };
    
    // Recherche par correspondance avec logique spéciale pour les adresses
    
    // D'abord, vérifier spécifiquement les cas d'adresse complémentaire
    if (_isAdditionalAddress(cleanHeader)) {
      return 'additionalAddress';
    }
    
    // Ensuite, vérifier l'adresse principale
    if (_isMainAddress(cleanHeader)) {
      return 'address';
    }
    
    // Recherche par correspondance exacte ou partielle pour les autres champs
    final orderedFields = [
      'firstName', 'lastName', 'email', 'phone',
      'country', 'gender', 'maritalStatus', 'zipCode', 'city', 'birthDate', 'roles', 'isActive'
    ];
    
    for (final fieldName in orderedFields) {
      if (fieldPatterns.containsKey(fieldName)) {
        final patterns = fieldPatterns[fieldName]!;
        for (final pattern in patterns) {
          if (_matchesPattern(cleanHeader, pattern)) {
            return fieldName;
          }
        }
      }
    }
    
    // Détection par analyse sémantique pour champs personnalisés
    return _detectCustomField(cleanHeader);
  }
  
  /// Nettoyer le nom d'en-tête pour la comparaison
  String _cleanHeaderName(String header) {
    return header
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Vérifier si un en-tête correspond à un pattern
  bool _matchesPattern(String cleanHeader, String pattern) {
    // Correspondance exacte
    if (cleanHeader == pattern) return true;
    
    // Correspondance exacte avec espaces
    if (cleanHeader.replaceAll(' ', '') == pattern.replaceAll(' ', '')) return true;
    
    // Pour éviter les faux positifs, n'utiliser la correspondance partielle
    // que si le pattern est assez long (plus de 4 caractères)
    if (pattern.length > 4) {
      if (cleanHeader.contains(pattern) || pattern.contains(cleanHeader)) {
        return true;
      }
    }
    
    // Correspondance floue (distance de Levenshtein) uniquement pour correspondance quasi-exacte
    return _calculateLevenshteinDistance(cleanHeader, pattern) <= 1;
  }
  
  /// Vérifier si un en-tête correspond à une adresse complémentaire
  bool _isAdditionalAddress(String cleanHeader) {
  final additionalKeywords = [
    'complement', 'complementaire', 'additional', 'additionnal', 
    'suite', 'appartement', 'apt', 'etage', 'batiment', 'bis', 'ter',
    'dadresse', 'daddress' // pour gérer les apostrophes supprimées
  ];    // Si contient un mot-clé de complément ET "adresse"/"address"
    final hasAddressWord = cleanHeader.contains('adresse') || cleanHeader.contains('address');
    final hasComplementKeyword = additionalKeywords.any((keyword) => cleanHeader.contains(keyword));
    
    return hasAddressWord && hasComplementKeyword;
  }
  
  /// Vérifier si un en-tête correspond à une adresse principale
  bool _isMainAddress(String cleanHeader) {
    final mainAddressPatterns = [
      'adresse', 'address', 'rue', 'street', 'domicile', 'residence',
      'full_address', 'adresse_complete', 'lieu', 'location', 'adresse_principale'
    ];
    
    // Si correspond à un pattern d'adresse principale
    for (final pattern in mainAddressPatterns) {
      if (_matchesPattern(cleanHeader, pattern)) {
        // Mais s'assurer que ce n'est pas une adresse complémentaire
        if (!_isAdditionalAddress(cleanHeader)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Calculer la distance de Levenshtein pour correspondance floue
  int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // suppression
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  /// Nettoyer et normaliser la valeur d'une cellule
  String? _cleanCellValue(dynamic rawValue) {
    if (rawValue == null) return null;
    
    String value = rawValue.toString().trim();
    
    // Enlever les caractères de contrôle et espaces inutiles
    value = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    
    // Enlever les guillemets encadrants
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    
    return value.isEmpty ? null : value;
  }
  
  /// Détecter les champs personnalisés par analyse sémantique
  String? _detectCustomField(String cleanHeader) {
    // Mots-clés pour identifier des champs personnalisés courants
    final customFieldPatterns = {
      'age': ['age', 'ans'],
      'profession': ['profession', 'métier', 'metier', 'travail', 'job', 'emploi'],
      'ville': ['ville', 'city', 'localité', 'localite'],
      'pays': ['pays', 'country', 'nation'],
      'notes': ['note', 'notes', 'commentaire', 'commentaires', 'observation'],
      'groupe': ['groupe', 'group', 'equipe', 'équipe', 'team'],
    };
    
    for (final entry in customFieldPatterns.entries) {
      final fieldName = entry.key;
      final patterns = entry.value;
      
      for (final pattern in patterns) {
        if (_matchesPattern(cleanHeader, pattern)) {
          return fieldName; // Retourner comme champ personnalisé
        }
      }
    }
    
    return null; // Champ non reconnu
  }
  
  /// Traiter et valider les données extraites
  Future<Map<String, dynamic>?> _processAndValidateData(
    Map<String, dynamic> data,
    ImportExportConfig config,
  ) async {
    final processedData = <String, dynamic>{};
    
    // Traitement intelligent des noms
    final firstName = _processName(data['firstName']);
    final lastName = _processLastName(data['lastName']);
    
    // Validation des champs requis avec logique flexible
    if (firstName == null || lastName == null) {
      // Essayer de diviser un nom complet si un seul champ est fourni
      final fullName = firstName ?? lastName ?? data['fullName'] ?? data['nom_complet'];
      if (fullName != null) {
        final String cleanFullName = fullName.toString().trim();
        final nameParts = cleanFullName.split(' ').where((String part) => part.isNotEmpty).toList();
        if (nameParts.length >= 2) {
          processedData['firstName'] = _processName(nameParts.first);
          processedData['lastName'] = _processLastName(nameParts.skip(1).join(' '));
        } else {
          return null; // Impossible de créer un nom valide
        }
      } else {
        return null; // Aucun nom valide trouvé
      }
    } else {
      processedData['firstName'] = firstName;
      processedData['lastName'] = lastName;
    }
    
    // Traitement de l'email avec validation
    if (data['email'] != null) {
      final email = _processEmail(data['email']);
      if (email != null && (!config.validateEmails || _isValidEmail(email))) {
        // Vérifier les doublons si requis
        if (!config.allowDuplicateEmail) {
          final existing = await _findExistingPersonByEmail(email);
          if (existing != null && !config.updateExisting) {
            return null; // Email déjà utilisé
          }
        }
        processedData['email'] = email;
      }
    }
    
    // Traitement du téléphone avec validation
    if (data['phone'] != null) {
      final phone = _processPhone(data['phone']);
      if (phone != null && (!config.validatePhones || _isValidPhone(phone))) {
        processedData['phone'] = phone;
      }
    }
    
    // Traitement du pays
    if (data['country'] != null) {
      processedData['country'] = _processCountry(data['country']);
    }
    
    // Traitement du genre
    if (data['gender'] != null) {
      processedData['gender'] = _processGender(data['gender']);
    }
    
    // Traitement du statut marital
    if (data['maritalStatus'] != null) {
      processedData['maritalStatus'] = _processMaritalStatus(data['maritalStatus']);
    }
    
    // Traitement de l'adresse
    if (data['address'] != null) {
      processedData['address'] = _processAddress(data['address']);
    }
    
    // Traitement de l'adresse complémentaire
    if (data['additionalAddress'] != null) {
      processedData['additionalAddress'] = _processAddress(data['additionalAddress']);
    }
    
    // Traitement du code postal
    if (data['zipCode'] != null) {
      processedData['zipCode'] = _processZipCode(data['zipCode']);
    }
    
    // Traitement de la ville
    if (data['city'] != null) {
      processedData['city'] = _processCity(data['city']);
    }
    
    // Traitement de la date de naissance
    if (data['birthDate'] != null) {
      final birthDate = _processDate(data['birthDate']);
      if (birthDate != null) {
        processedData['birthDate'] = birthDate;
      }
    }
    
    // Traitement des rôles
    if (data['roles'] != null) {
      final roles = _processRoles(data['roles']);
      if (roles.isNotEmpty) {
        processedData['roles'] = roles;
      }
    }
    
    // Traitement du statut actif
    if (data['isActive'] != null) {
      processedData['isActive'] = _processActiveStatus(data['isActive']);
    } else {
      processedData['isActive'] = true; // Par défaut actif
    }
    
    return processedData;
  }
  
  /// Construire un objet Person à partir des données traitées
  Person _buildPersonFromData(Map<String, dynamic> data) {
    return Person(
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      phone: data['phone'],
      country: data['country'],
      birthDate: data['birthDate'],
      gender: data['gender'],
      maritalStatus: data['maritalStatus'],
      address: data['address'],
      additionalAddress: data['additionalAddress'],
      zipCode: data['zipCode'],
      city: data['city'],
      roles: data['roles'] ?? <String>[],
      customFields: data['customFields'] ?? <String, dynamic>{},
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convertir une ligne CSV en Person avec validation robuste
  Future<Person?> _rowToPerson(
    List<dynamic> row,
    List<String> headers,
    Map<String, String> mapping,
    ImportExportConfig config,
  ) async {
    try {
      // Validation de base
      if (row.isEmpty || headers.isEmpty) {
        return null;
      }
      
      // Étendre la ligne si nécessaire pour correspondre aux en-têtes
      final extendedRow = List<dynamic>.from(row);
      while (extendedRow.length < headers.length) {
        extendedRow.add('');
      }
      final data = <String, dynamic>{};
      final customFields = <String, dynamic>{};
      
      // Extraire et nettoyer toutes les données
      for (int i = 0; i < headers.length && i < extendedRow.length; i++) {
        final header = headers[i];
        final rawValue = extendedRow[i];
        final cleanValue = _cleanCellValue(rawValue);
        
        if (cleanValue != null && cleanValue.isNotEmpty) {
          if (mapping.containsKey(header)) {
            final field = mapping[header]!;
            // Champs standards du modèle Person
            if (standardFields.contains(field)) {
              data[field] = cleanValue;
            } else {
              // Champs personnalisés
              customFields[field] = cleanValue;
            }
          } else {
            // Essayer de détecter automatiquement le champ
            final detectedField = _detectFieldType(header);
            if (detectedField != null) {
              if (standardFields.contains(detectedField)) {
                data[detectedField] = cleanValue;
              } else {
                customFields[detectedField] = cleanValue;
              }
            } else {
              // Ajouter comme champ personnalisé avec le nom d'origine
              customFields[header] = cleanValue;
            }
          }
        }
      }
      
      // Validation et nettoyage intelligents des données
      final processedData = await _processAndValidateData(data, config);
      if (processedData == null) {
        return null; // Données invalides
      }
      
      // Combiner les champs personnalisés avec ceux existants
      if (customFields.isNotEmpty) {
        processedData['customFields'] = customFields;
      }
      
      return _buildPersonFromData(processedData);
    } catch (e) {
      print('Erreur lors de la conversion de ligne: $e');
      return null;
    }
  }

  /// Convertir une Map JSON en Person
  Person? _mapToPerson(Map<String, dynamic> data, ImportExportConfig config) {
    try {
      // Validation des champs requis
      if (data['firstName']?.toString().trim().isEmpty != false || 
          data['lastName']?.toString().trim().isEmpty != false) {
        return null;
      }
      
      // Validation email
      if (config.validateEmails && data['email'] != null) {
        if (!_isValidEmail(data['email'].toString())) {
          return null;
        }
      }
      
      // Parser la date de naissance
      DateTime? birthDate;
      if (data['birthDate'] != null) {
        birthDate = _parseDate(data['birthDate'].toString());
      }
      
      // Parser les rôles
      List<String> roles = [];
      if (data['roles'] is List) {
        roles = List<String>.from(data['roles']);
      } else if (data['roles'] is String) {
        roles = data['roles'].split(',').map((String r) => r.trim()).where((String r) => r.isNotEmpty).toList();
      }
      
      return Person(
        firstName: data['firstName'].toString().trim(),
        lastName: data['lastName'].toString().trim(),
        email: data['email']?.toString().trim(),
        phone: data['phone']?.toString().trim(),
        address: data['address']?.toString().trim(),
        birthDate: birthDate,
        roles: roles,
        customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
        isActive: data['isActive'] != false && data['isActive'] != 'Non',
      );
    } catch (e) {
      print('Erreur lors de la conversion de Map: $e');
      return null;
    }
  }

  /// Sauvegarder une personne
  Future<bool> _savePerson(Person person, ImportExportConfig config) async {
    try {
      // 🆕 Ajouter automatiquement le rôle "membre" aux personnes importées
      final rolesWithMembre = Set<String>.from(person.roles);
      rolesWithMembre.add('membre');
      final personWithMembre = person.copyWith(roles: rolesWithMembre.toList());
      
      if (config.updateExisting && personWithMembre.email != null) {
        final existing = await _peopleService.findByEmail(personWithMembre.email!);
        if (existing != null) {
          final updated = personWithMembre.copyWith(id: existing.id);
          await _peopleService.update(existing.id!, updated);
          print('✅ Personne mise à jour avec rôle membre: ${personWithMembre.fullName}');
          return true;
        }
      }
      
      await _peopleService.create(personWithMembre);
      print('✅ Nouvelle personne créée avec rôle membre: ${personWithMembre.fullName}');
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      return false;
    }
  }

  /// Valider un email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  /// Valider un téléphone
  bool _isValidPhone(String phone) {
    return RegExp(r'^[\d\s\+\-\(\)\.]+$').hasMatch(phone) && phone.length >= 8;
  }

  /// Parser une date depuis différents formats
  DateTime? _parseDate(String dateString) {
    try {
      // Format ISO
      if (dateString.contains('T') || dateString.contains('-')) {
        return DateTime.parse(dateString);
      }
      
      // Format DD/MM/YYYY
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Format DD-MM-YYYY
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Partager un fichier exporté
  Future<void> shareExportFile(
    String filePath, {
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    await ShareUtils.shareFile(
      XFile(filePath),
      sharePositionOrigin: sharePositionOrigin,
      context: context,
    );
  }

  /// Obtenir le template d'import CSV
  String getCsvTemplate({String templateName = 'default'}) {
    final template = importTemplates[templateName] ?? importTemplates['default']!;
    final headers = template.keys.toList();
    
    final csvRows = [
      headers,
      // Ligne d'exemple
      [
        'Jean',
        'Dupont', 
        'jean.dupont@email.com',
        '0123456789',
        '123 Rue de la Paix, 75001 Paris',
        '1990-01-01',
        'membre,leader',
      ],
    ];
    
    return const ListToCsvConverter().convert(csvRows);
  }

  // ===========================
  // MÉTHODES DE TRAITEMENT ROBUSTE DES DONNÉES
  // ===========================

  /// Traiter et normaliser un prénom
  String? _processName(dynamic value) {
    if (value == null) return null;
    String name = value.toString().trim();
    if (name.isEmpty) return null;
    
    // Capitaliser la première lettre de chaque mot
    return name.split(' ')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Traiter et normaliser un nom de famille (tout en majuscules)
  String? _processLastName(dynamic value) {
    if (value == null) return null;
    String name = value.toString().trim();
    if (name.isEmpty) return null;
    
    // Convertir tout en majuscules
    return name.toUpperCase();
  }
  
  /// Traiter et valider un email
  String? _processEmail(dynamic value) {
    if (value == null) return null;
    String email = value.toString().trim().toLowerCase();
    return email.isEmpty ? null : email;
  }
  
  /// Traiter et normaliser un numéro de téléphone
  String? _processPhone(dynamic value) {
    if (value == null) return null;
    String phone = value.toString().trim();
    
    // Enlever tous les caractères non numériques sauf + au début
    phone = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    
    // Ajouter des espaces pour la lisibilité si le numéro est long
    if (phone.length >= 10) {
      if (phone.startsWith('+33')) {
        // Format français
        phone = phone.replaceAllMapped(
          RegExp(r'^(\+33)(\d{1})(\d{2})(\d{2})(\d{2})(\d{2})$'),
          (match) => '${match[1]} ${match[2]} ${match[3]} ${match[4]} ${match[5]} ${match[6]}'
        );
      } else if (phone.length == 10 && !phone.startsWith('+')) {
        // Format français sans indicatif
        phone = phone.replaceAllMapped(
          RegExp(r'^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$'),
          (match) => '${match[1]} ${match[2]} ${match[3]} ${match[4]} ${match[5]}'
        );
      }
    }
    
    return phone.isEmpty ? null : phone;
  }
  
  /// Traiter et normaliser une adresse
  String? _processAddress(dynamic value) {
    if (value == null) return null;
    String address = value.toString().trim();
    return address.isEmpty ? null : address;
  }
  
  /// Traiter et parser une date
  DateTime? _processDate(dynamic value) {
    if (value == null) return null;
    return _parseDate(value.toString());
  }
  
  /// Traiter et normaliser les rôles
  List<String> _processRoles(dynamic value) {
    if (value == null) return <String>[];
    
    String rolesStr = value.toString();
    List<String> roles = [];
    
    // Diviser par différents séparateurs possibles
    final separators = [',', ';', '|', '/', '\n'];
    for (final separator in separators) {
      if (rolesStr.contains(separator)) {
        roles = rolesStr.split(separator)
            .map((String r) => r.trim())
            .where((String r) => r.isNotEmpty)
            .toList();
        break;
      }
    }
    
    // Si aucun séparateur trouvé, traiter comme un seul rôle
    if (roles.isEmpty && rolesStr.trim().isNotEmpty) {
      roles = [rolesStr.trim()];
    }
    
    return roles;
  }
  
  /// Traiter le statut actif
  bool _processActiveStatus(dynamic value) {
    if (value == null) return true;
    
    String status = value.toString().trim().toLowerCase();
    
    // Valeurs considérées comme inactives
    final inactiveValues = [
      'false', 'non', 'no', 'n', '0', 'inactif', 'inactive', 
      'disabled', 'desactive', 'désactivé', 'off'
    ];
    
    return !inactiveValues.contains(status);
  }
  
  /// Traiter et normaliser un pays
  String? _processCountry(dynamic value) {
    if (value == null) return null;
    String country = value.toString().trim();
    
    // Capitalisation du nom du pays
    if (country.length > 1) {
      country = country[0].toUpperCase() + country.substring(1).toLowerCase();
    }
    
    // Quelques normalisations communes
    final countryMappings = {
      'france': 'France',
      'usa': 'États-Unis',
      'us': 'États-Unis',
      'uk': 'Royaume-Uni',
      'canada': 'Canada',
      'allemagne': 'Allemagne',
      'germany': 'Allemagne',
      'espagne': 'Espagne',
      'spain': 'Espagne',
      'italie': 'Italie',
      'italy': 'Italie',
    };
    
    return countryMappings[country.toLowerCase()] ?? country;
  }
  
  /// Traiter et normaliser le genre
  String? _processGender(dynamic value) {
    if (value == null) return null;
    String gender = value.toString().trim().toLowerCase();
    
    // Normalisation des valeurs de genre
    final genderMappings = {
      'm': 'Masculin',
      'male': 'Masculin',
      'homme': 'Masculin',
      'man': 'Masculin',
      'masculin': 'Masculin',
      'f': 'Féminin',
      'female': 'Féminin',
      'femme': 'Féminin',
      'woman': 'Féminin',
      'féminin': 'Féminin',
      'feminin': 'Féminin',
    };
    
    return genderMappings[gender] ?? (gender.isEmpty ? null : gender[0].toUpperCase() + gender.substring(1));
  }
  
  /// Traiter et normaliser le statut marital
  String? _processMaritalStatus(dynamic value) {
    if (value == null) return null;
    String status = value.toString().trim().toLowerCase();
    
    // Normalisation des statuts maritaux
    final statusMappings = {
      'marie': 'Marié(e)',
      'marié': 'Marié(e)',
      'mariee': 'Marié(e)',
      'mariée': 'Marié(e)',
      'married': 'Marié(e)',
      'celibataire': 'Célibataire',
      'célibataire': 'Célibataire',
      'single': 'Célibataire',
      'divorce': 'Divorcé(e)',
      'divorcé': 'Divorcé(e)',
      'divorcee': 'Divorcé(e)',
      'divorcée': 'Divorcé(e)',
      'divorced': 'Divorcé(e)',
      'veuf': 'Veuf(ve)',
      'veuve': 'Veuf(ve)',
      'widow': 'Veuf(ve)',
      'widower': 'Veuf(ve)',
    };
    
    return statusMappings[status] ?? (status.isEmpty ? null : status[0].toUpperCase() + status.substring(1));
  }
  
  /// Traiter et normaliser un code postal
  String? _processZipCode(dynamic value) {
    if (value == null) return null;
    String zipCode = value.toString().trim();
    
    // Enlever tous les caractères non numériques
    zipCode = zipCode.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format français (5 chiffres)
    if (zipCode.length == 5) {
      return zipCode;
    }
    
    // Compléter avec des zéros si nécessaire (pour certains codes postaux français)
    if (zipCode.length == 4) {
      return '0$zipCode';
    }
    
    return zipCode.isEmpty ? null : zipCode;
  }
  
  /// Traiter et normaliser une ville
  String? _processCity(dynamic value) {
    if (value == null) return null;
    String city = value.toString().trim();
    
    if (city.isEmpty) return null;
    
    // Capitalisation des mots
    final words = city.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      
      // Gestion des articles et prépositions en français
      final articles = ['le', 'la', 'les', 'du', 'de', 'des', 'à', 'au', 'aux', 'sur', 'sous'];
      if (articles.contains(word.toLowerCase()) && words.indexOf(word) > 0) {
        return word.toLowerCase();
      }
      
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    
    return capitalizedWords.join(' ');
  }
  
  /// Rechercher une personne existante par email
  Future<Person?> _findExistingPersonByEmail(String email) async {
    try {
      final people = await _peopleService.getAll();
      for (final person in people) {
        if (person.email?.toLowerCase() == email.toLowerCase()) {
          return person;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

}