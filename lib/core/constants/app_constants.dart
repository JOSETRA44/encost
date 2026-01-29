/// Constantes de la aplicación
class AppConstants {
  // Nombres de cajas de Hive
  static const String surveysBoxName = 'surveys_box';
  static const String responsesBoxName = 'responses_box';
  static const String settingsBoxName = 'settings_box';

  // Keys de configuración
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Rutas de assets
  static const String surveysAssetPath = 'assets/surveys/';

  // Límites de validación
  static const int maxTextLength = 1000;
  static const int maxNumericValue = 999999;

  // Formatos de fecha
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Configuración de exportación
  static const String exportFolderName = 'encost_exports';
  static const String excelExtension = '.xlsx';
  static const String csvExtension = '.csv';

  // Animación
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 200);
}
