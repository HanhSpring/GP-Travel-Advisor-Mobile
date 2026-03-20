import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_datasource.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/home/data/datasources/home_datasource.dart';
import '../../features/home/data/repositories/mock_home_repository.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/home_usecases.dart';
import '../../features/home/presentation/cubit/explore_cubit.dart';
import '../../features/itinerary/data/datasources/itinerary_datasource.dart';
import '../../features/itinerary/data/repositories/itinerary_repository_impl.dart';
import '../../features/itinerary/domain/repositories/itinerary_repository.dart';
import '../../features/itinerary/domain/usecases/itinerary_usecases.dart';
import '../../features/itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/get_recent_activities_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/review/data/datasources/review_datasource.dart';
import '../../features/review/data/repositories/review_repository_impl.dart';
import '../../features/review/domain/repositories/review_repository.dart';
import '../../features/review/domain/usecases/get_itinerary_for_review_usecase.dart';
import '../../features/review/presentation/cubit/review_cubit.dart';
import '../../features/search/data/datasources/search_mock_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/get_recent_searches.dart';
import '../../features/search/domain/usecases/search_locations.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';
import '../../features/city_detail/data/datasources/city_detail_mock_data_source.dart';
import '../../features/city_detail/data/repositories/city_detail_repository_impl.dart';
import '../../features/city_detail/domain/repositories/city_detail_repository.dart';
import '../../features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import '../../features/city_detail/presentation/cubit/city_detail_cubit.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

/// 🔌 Single registration point for all dependencies.
Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // ── Auth DataSources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthDataSource>(() => MockAuthDataSource());

  // ── Auth Repository ────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // ── Auth UseCases ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // ── Auth Cubit ─────────────────────────────────────────────────────────────
  sl.registerFactory(() => AuthCubit(loginUseCase: sl(), registerUseCase: sl()));

  // ── Home DataSources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeDataSource>(() => MockHomeDataSource());

  // ── Home Repository ────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));

  // ── Home UseCases ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetSuggestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDestinationsUseCase(sl()));
  sl.registerLazySingleton(() => GetHotelsUseCase(sl()));

  // ── Explore Cubit ──────────────────────────────────────────────────────────
  sl.registerFactory(() => ExploreCubit(
        getSuggestions: sl(),
        getDestinations: sl(),
        getHotels: sl(),
      ));

  // ── Itinerary Feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<ItineraryDataSource>(() => MockItineraryDataSource());
  sl.registerLazySingleton<ItineraryRepository>(() => ItineraryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItinerariesUseCase(sl()));
  sl.registerLazySingleton(() => GetItinerarySummaryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteItineraryUseCase(sl()));
  sl.registerFactory(() => ItineraryCubit(
        getItineraries: sl(),
        getSummary: sl(),
        deleteItinerary: sl(),
      ));

  // ── Profile Feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(() => MockProfileDataSource());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentActivitiesUseCase(sl()));
  sl.registerFactory(() => ProfileCubit(
        getProfile: sl(),
        getRecentActivities: sl(),
      ));

  // ── Review Feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ReviewDataSource>(() => MockReviewDataSource());
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItineraryForReviewUseCase(sl()));
  sl.registerFactory(() => ReviewCubit(getItineraryForReview: sl()));

  // ── Search Feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<SearchMockDataSource>(() => SearchMockDataSourceImpl());
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => GetRecentSearches(sl()));
  sl.registerLazySingleton(() => SearchLocations(sl()));
  sl.registerFactory(() => SearchCubit(sl(), sl()));

  // ── City Detail Feature ────────────────────────────────────────────────────
  sl.registerLazySingleton<CityDetailDataSource>(() => CityDetailMockDataSource());
  sl.registerLazySingleton<CityDetailRepository>(() => CityDetailRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetCityOverviewUseCase(sl()));
  sl.registerFactory(() => CityDetailCubit(sl()));
}
