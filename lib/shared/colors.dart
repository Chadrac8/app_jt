import 'package:flutter/material.dart';

/// Palette de couleurs raffinée pour l'application Jubilé Tabernacle
/// Basée sur le rouge bordeaux #850606 avec états interactifs définis
class AppColors {
  // Couleur principale avec états
  static const Color primary = Color(0xFF850606); // Rouge bordeaux
  static const Color primaryHover = Color(0xFFA50707); // Hover/Focus
  static const Color primaryActive = Color(0xFF5C0404); // Active/Pressed
  
  // Couleurs de fond
  static const Color background = Color(0xFFF8F9FA); // Background
  static const Color surface = Color(0xFFE9ECEF); // Surface
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212529); // Texte principal
  static const Color textSecondary = Color(0xFF6C757D); // Text secondary
  static const Color textTertiary = Color(0xFF6C757D); // Text tertiary
  
  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50); // Vert
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Rouge
  static const Color info = Color(0xFF2196F3); // Bleu
  
  // Variantes du rouge bordeaux
  static const Color primaryLight = Color(0xFFA50707); // Hover/Focus
  static const Color primaryDark = Color(0xFF5C0404); // Active/Pressed
  
  // Couleurs spéciales
  static const Color white = Color(0xFFFFFFFF); // Blanc pur
  static const Color lightBackground = Color(0xFFF8F9FA); // Background
  static const Color lightSurface = Color(0xFFE9ECEF); // Surface
  
  // Transparences
  static const Color overlay = Color(0x80000000); // Noir 50% transparent
  static const Color primaryOverlay = Color(0x33850606); // Rouge bordeaux 20% transparent
  
  // États interactifs
  static const Color hoverState = Color(0xFFA50707); // Hover/Focus
  static const Color activeState = Color(0xFF5C0404); // Active/Pressed
  static const Color disabledState = Color(0x606C757D); // Disabled (text secondary transparent)
}
