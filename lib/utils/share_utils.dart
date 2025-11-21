import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Service utilitaire pour gérer le partage de fichiers de manière robuste
class ShareUtils {
  /// Partager des fichiers avec gestion automatique de la position d'origine pour iOS
  static Future<ShareResult?> shareFiles(
    List<XFile> files, {
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    try {
      Rect? finalSharePositionOrigin;
      
      // Sur iOS, nous devons fournir une position d'origine
      if (Platform.isIOS) {
        if (sharePositionOrigin != null) {
          finalSharePositionOrigin = sharePositionOrigin;
        } else if (context != null) {
          // Essayer d'obtenir la position depuis le contexte
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            finalSharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
          } else {
            // Position par défaut au centre de l'écran
            final size = MediaQuery.of(context).size;
            finalSharePositionOrigin = Rect.fromLTWH(
              size.width / 2 - 100, 
              size.height / 2 - 100, 
              200, 
              200
            );
          }
        } else {
          // Position par défaut
          finalSharePositionOrigin = const Rect.fromLTWH(100, 100, 200, 200);
        }
      }
      
      return await Share.shareXFiles(
        files,
        text: text,
        subject: subject,
        sharePositionOrigin: finalSharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Erreur lors du partage avec sharePositionOrigin: $e');
      
      // Fallback pour Android ou en cas d'erreur
      try {
        return await Share.shareXFiles(
          files,
          text: text,
          subject: subject,
        );
      } catch (e2) {
        debugPrint('Erreur lors du partage (fallback): $e2');
        return null;
      }
    }
  }
  
  /// Partager un seul fichier
  static Future<ShareResult?> shareFile(
    XFile file, {
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    return shareFiles(
      [file],
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
      context: context,
    );
  }
  
  /// Partager du texte simple
  static Future<void> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    try {
      Rect? finalSharePositionOrigin;
      
      // Sur iOS, nous devons fournir une position d'origine
      if (Platform.isIOS && sharePositionOrigin == null && context != null) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          finalSharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
        } else {
          final size = MediaQuery.of(context).size;
          finalSharePositionOrigin = Rect.fromLTWH(
            size.width / 2 - 100, 
            size.height / 2 - 100, 
            200, 
            200
          );
        }
      } else {
        finalSharePositionOrigin = sharePositionOrigin;
      }
      
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: finalSharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Erreur lors du partage de texte: $e');
      // Fallback sans sharePositionOrigin
      await Share.share(text, subject: subject);
    }
  }
}