import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../../features/survey/data/datasources/survey_local_datasource.dart';
import '../../features/survey/data/datasources/response_local_datasource.dart';
import '../../features/survey/data/repositories/survey_repository_impl.dart';
import '../../features/survey/data/repositories/response_repository_impl.dart';
import '../../features/survey/domain/repositories/survey_repository.dart';
import '../../features/survey/domain/repositories/response_repository.dart';
import '../../features/survey/domain/usecases/survey_usecases.dart';
import '../../features/survey/domain/usecases/response_usecases.dart';

/// Service Locator - Inyección de Dependencias
/// 
/// Principio de Inversión de Dependencias (DIP):
/// Las capas superiores no conocen las implementaciones concretas
final sl = GetIt.instance;

/// Configura todas las dependencias de la aplicación
Future<void> setupDependencyInjection() async {
  // =============== CORE ===============
  // Database Helper (SQLite)
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper());
  
  // Inicializar base de datos
  await sl<DatabaseHelper>().database;
  
  // =============== DATA SOURCES ===============
  sl.registerLazySingleton<SurveyLocalDataSource>(
    () => SurveyLocalDataSourceImpl(
      dbHelper: sl<DatabaseHelper>(),
    ),
  );
  
  sl.registerLazySingleton<ResponseLocalDataSource>(
    () => ResponseLocalDataSourceImpl(
      dbHelper: sl<DatabaseHelper>(),
    ),
  );
  
  // =============== REPOSITORIES ===============
  sl.registerLazySingleton<SurveyRepository>(
    () => SurveyRepositoryImpl(
      localDataSource: sl<SurveyLocalDataSource>(),
    ),
  );
  
  sl.registerLazySingleton<ResponseRepository>(
    () => ResponseRepositoryImpl(
      localDataSource: sl<ResponseLocalDataSource>(),
    ),
  );
  
  // =============== USE CASES - Survey ===============
  sl.registerLazySingleton(() => LoadSurveyFromJson(sl<SurveyRepository>()));
  sl.registerLazySingleton(() => GetSurveyById(sl<SurveyRepository>()));
  sl.registerLazySingleton(() => GetAllSurveys(sl<SurveyRepository>()));
  sl.registerLazySingleton(() => SaveSurvey(sl<SurveyRepository>()));
  
  // =============== USE CASES - Response ===============
  sl.registerLazySingleton(() => SaveResponse(sl<ResponseRepository>()));
  sl.registerLazySingleton(() => UpdateResponse(sl<ResponseRepository>()));
  sl.registerLazySingleton(() => GetResponsesBySurveyId(sl<ResponseRepository>()));
  sl.registerLazySingleton(() => ExportResponsesToExcel(sl<ResponseRepository>()));
  sl.registerLazySingleton(() => ExportResponsesToCsv(sl<ResponseRepository>()));
}
