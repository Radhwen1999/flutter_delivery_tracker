import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'websocket_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'connectivity_service.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/data/datasources/tracking_remote_datasource.dart';
import '../../features/tracking/data/datasources/tracking_local_datasource.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';


final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  
  // Core Services
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  // Data Sources
  getIt.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSourceImpl(
      supabaseClient: getIt(),
      webSocketService: getIt(),
    ),
  );
  getIt.registerLazySingleton<TrackingLocalDataSource>(
    () => TrackingLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      connectivityService: getIt(),
    ),
  );

  
  // BLoCs
  getIt.registerFactory<TrackingBloc>(
    () => TrackingBloc(
      trackingRepository: getIt(),
      webSocketService: getIt(),
      locationService: getIt(),
      notificationService: getIt(),
    ),
  );
}
