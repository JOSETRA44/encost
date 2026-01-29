import 'package:flutter/material.dart';

/// Paleta de colores con alto contraste para exteriores
/// 
/// Optimizada para lectura bajo luz solar directa
class AppColors {
  // Primarios - Alto contraste
  static const Color primary = Color(0xFF1565C0); // Azul intenso
  static const Color primaryDark = Color(0xFF0D47A1); // Azul más oscuro
  static const Color primaryLight = Color(0xFF42A5F5); // Azul claro
  
  // Secundarios
  static const Color secondary = Color(0xFFFF6F00); // Naranja vibrante
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF9800);
  
  // Acentos
  static const Color accent = Color(0xFF00C853); // Verde éxito
  static const Color accentError = Color(0xFFD32F2F); // Rojo error
  static const Color accentWarning = Color(0xFFFFA000); // Amarillo advertencia
  
  // Fondos - Máximo contraste
  static const Color backgroundLight = Color(0xFFFAFAFA); // Casi blanco
  static const Color backgroundDark = Color(0xFF121212); // Negro profundo
  static const Color surfaceLight = Color(0xFFFFFFFF); // Blanco puro
  static const Color surfaceDark = Color(0xFF1E1E1E); // Gris muy oscuro
  
  // Textos - Contraste AAA
  static const Color textPrimaryLight = Color(0xFF000000); // Negro puro
  static const Color textSecondaryLight = Color(0xFF424242); // Gris oscuro
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Blanco puro
  static const Color textSecondaryDark = Color(0xFFE0E0E0); // Gris claro
  
  // Bordes y divisores
  static const Color dividerLight = Color(0xFF757575); // Gris medio
  static const Color dividerDark = Color(0xFF616161); // Gris medio oscuro
  
  // Estados
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x29000000);
  
  // Gradientes para botones (alto impacto visual)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
